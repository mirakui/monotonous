require 'rubygems'
require 'mechanize'
require 'pit'
require 'kconv'
require 'loggable'

# http://d.hatena.ne.jp/otn/20090429/p1
class WWW::Mechanize
  def set_hook
    @post_connect_hook.hooks << Proc.new do |params|
      params[:response_body] = NKF.nkf("-wm0",params[:response_body])
      params[:response]["Content-Type"]="text/html; charset=utf-8"
    end
  end
end

module MirakuiDmm
  class DmmClient
    include Gena::Loggable

    OPEN_TIMEOUT = 30
    RETRY_MAX = 3

    def initialize
      @agent = WWW::Mechanize.new
      @agent.set_hook
      @dmm_base = 'http://www.dmm.com/'
    end

    def test
      pp search('蒼井そら')
      #p search('asdf')
    end

    def search(query)
      get dmm_base + '/rental/'

      # 検索フォームにクエリを入力して送信
      f = page.form_with(:name=>'search_form')
      page.encoding = 'euc-jp'
      f.field_with(:name=>'searchstr').value = query
      f.submit

      # DMMエンコードされた検索クエリ文字列を取得
      searchstr = page.uri.to_s[%r(/searchstr=.*?/)]
      result = []
      [false, true].each do |is_adult|
        textlist_uri_str = "#{dmm_base(is_adult)}rental/-/list/=/article=search/#{searchstr}view=text/sort=review_rank/"
        get textlist_uri_str
        page.links_with(:href=>%r(/rental/-/detail/=/)).each do |link|
          result << {
            :uri      => link.href,
            :title    => link.text,
            :is_adult => is_adult
          }
        end
      end

      result

    end

    def dmm_base(is_adult=false)
      is_adult ? 'http://www.dmm.co.jp/' : 'http://www.dmm.com/'
    end

    private

    def get(uri)
      retry_count = 0
      begin
        timeout(OPEN_TIMEOUT) do
          @agent.get uri
          raise "Error result" if @agent.page.uri.to_s=~%r(/error/)
        end
      rescue Object => e
        if retry_count < RETRY_MAX
          retry_count += 1
          logger.warn "Retry(#{retry_count}): #{uri}"
          retry
        else
          raise e
        end
      end 
      page
    end

    def page
      @agent.page
    end

  end
end

#__END__
dmm = MirakuiDmm::DmmClient.new
dmm.test

