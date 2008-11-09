<?php
$lines = isset($_GET['lines']) ? intval($_GET['lines']) : 10;
$conf = array(
          'chikuwa' => array(
            array(
              'name' => 'follotter-crawler log',
              'cmd'  => "/home/inaruta/projects/follotter-crawler/script/log -n $lines",
            ),
          ),
        );
$hostname = chop(`hostname`);
$filename = null;
$host_conf = $conf[$hostname];
$dump = null;
if (isset($_GET['log'])) {
  $conf_index = intval($_GET['log']);
  $cmd = $host_conf[$conf_index]{'cmd'};
  $filename = $host_conf[$conf_index]{'name'};
  $dump = `$cmd`;
}
?>
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html: charset=utf-8"/>
  <title>webtail <?php echo $hostname ?> <?php echo $filename ?></title>
</head>
<body>
<h1>webtail <?php echo $hostname ?></h1>
<form action="./index.php" method="GET">
  <p>file:
    <select name="log">
      <?php
        for ($i=0; $i<count($host_conf); $i++) {
          echo '<option value='.$i.'>'.$host_conf[$i]{'name'}."</option>";
        }
      ?>
    </select>
  lines:
    <input type="text" name="lines" size="5" value="<?php echo $lines ?>"/>
    <input type="submit"/>
  </p>
</form>
<?php
  if (isset($dump)) {
    echo "<pre>$dump</pre>";
  }
?>
</body>
</html>
