require 'rubygems'
require 'mechanize'
require 'pit'
require 'logger'
require 'kconv'
require 'pp'

module MirakuiDmm
  OPEN_TIMEOUT = 30
  class DmmRegister
    def initialize
      @agent = WWW::Mechanize.new
    end

    def test
      p search('タイタニック').length
      p search('asdf').length
    end

    def search(query)
      @agent.get 'http://www.dmm.com/rental/'
      f = @agent.page.form_with(:name=>'search_form')
      f.field_with(:name=>'searchstr').value = query.toeuc
      f.submit
      if (@agent.page / 'span.strong')=~/見つかりませんでした/
        return []
      else
        @agent.page.links.each do |a|
          puts a.text if a.href=~%r(/rental/-/detail/)
        end
      end
    end

    def get(uri)
      uri = query
      retry_count = 0
      begin
        timeout(OPEN_TIMEOUT) do
          result = @agent.get uri
          raise "Error result" if result.uri.to_s=~%r(/error/)
          return result
        end
      rescue Object => e
        if retry_count < RETRY_MAX
          retry_count += 1
          @log.warn "Retry(#{retry_count}): #{uri}"
          retry
        else
          raise e
        end
      end 
    end
  end
end

#__END__
dmm = MirakuiDmm::DmmRegister.new
dmm.test
