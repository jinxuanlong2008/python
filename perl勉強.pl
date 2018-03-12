#
# VRF名は重複していないことが前提となっている。
#

my $path;
my @filename;
my $filename;
my $buf;
my @bufl;
my @tuv4addr;
my @ptuv4addr;
my @tundest;
my @tunsrc;
my @dhcpnw;
my @dgw;
my @giv6addr;
my @vrf;
my @vrfs;
my @tnum;
my $i;
my $j;
my $v;
my $u;
my $tunnelnum;
my $tnum;

#open TEST,'>test.txt';
#debug用ファイル

$flagT = 0;
#Tunnelインターフェイス内の設定を判別するための変数
$flagG2 = 0;
#Gi2インターフェイス内の設定を判別するための変数
$flagr = 0;
#ip route内の設定を判別するための変数
$flagD = 0;
#DHCPプール内の設定を判別するための変数
$flagDv = 0;
#特定のvrfのDHCPプール内の設定を判別するための変数

$path = "C:/Users/nwrd/Desktop/ciscoコンフィグ/*";
#コンフィグに入っているフォルダ名を指定
my @filename = glob($path);

open B,'> pCPE_config.txt';

foreach my $filename (@filename) {
#ファイル分繰り返し処理を実行
	open FH, $filename or die $!;	
	$flagTa = 0;
	#一番初めのTunnelインターフェイスのみ処理するための変数
	#ファイルごとに0に戻す
	
	while ($data = <FH>) {
		chomp $data;
		if($data =~ /interface Tunnel/) {
			$flagT = 1;
			#特定行でフラグを建てる
		}
		if($data eq " tunnel path-mtu-discovery"){
			$flagT = 0;
			#特定行でフラグを削除
		}
		if($data eq "interface GigabitEthernet2") {
			$flagG2 = 1;
			#特定行でフラグを建てる
		}
		if($data eq "service-policy output IPv6-U-Plane"){
			$flagG2 = 0;
			#特定行でフラグを削除
		}
		if($flagT == 1){
		#Tunnelインターフェイス内変数抽出
			if ($data =~ /ip address/) {
			#フラグがある状態で特定行がある場合は処理
			$buf = $data;
			$buf =~ /address (.+) 255\.255\.255\.252/;
			push(@tuv4addr,$1);
			#特定の文字列に囲まれたの中身をリストの最後に格納
			$tunnelnum = $tunnelnum+1;
			#tunnelの数を変数に格納
			}
			if ($data =~ /tunnel destination/) {
			$buf = $data;
			$buf =~ /destination /;
			push(@tundest,$');
			#特定の文字列に以降をリストの最後に格納
			}
			if ($data =~ /vrf forwarding/) {
			$buf = $data;
			$buf =~ /forwarding /;
			push(@vrf,$');
			#特定の文字列に以降をリストの最後に格納
			}
		}
		if($flagG2 == 1){
			if ($data =~ /ipv6 address/) {
			#フラグがある状態で特定行がある場合は処理
			$buf = $data;
			$buf =~ /address (.+)\/64/;
			push(@giv6addr,$1);
			#特定の文字列に囲まれたの中身をリストの最後に格納
			}
		}
	}
	push(@tnum,$tunnelnum);
	#vCPEのトンネルの数をリストに格納
	$tunnelnum = 0;
	#トンネルの数を格納する変数を0に戻す。
}
close FH;

$u = 0;

foreach my $tnum (@tnum) {
	for ($i = 0;$i < $tnum;$i++){
	push(@tunsrc,$giv6addr[$u]);
	#作成したアドレスをリストの最後に格納
	}
	$u = $u+1;
}

my $length = @tuv4addr;

print "要素数 $length
";

foreach my $tuv4addr (@tuv4addr) {
	@bufl = split(/\./,$tuv4addr);
	$buf = @bufl[3] - 1;
	#vCPEのtunnelのv4アドレスから、pCPEのtunnelのv4アドレスを作る処理
	push(@ptuv4addr,join '.', @bufl[0], @bufl[1], @bufl[2], $buf);
	#作成したアドレスをリストの最後に格納
}
my $length = @ptuv4addr;

print "要素数 $length
";


foreach my $vrf (@vrf) {
	$buf = $vrf;
	$buf =~ s/\_/\\\_/g;
	#vrf名検索用にvrf名にエスケープ文字を追加する処理
	push(@vrfs,$buf);
}

$j=@tuv4addr-1;
#配列の要素数を取得;
for ($z = 0; $z <= $j;$z++){
	foreach my $filename (@filename) {
	#ファイル分繰り返し処理を実行
		open FH, $filename or die $!;
		while ($data = <FH>) {
			chomp $data;
			#vrfの名前でファイルの検索を行う。
			if($data =~ /ip route vrf $vrfs[$z] / and $data =~ /$ptuv4addr[$z]$/) {
			$buf = $data;
			print TEST "$data
";
			$buf =~ /ip route vrf $vrfs[$z] (.+) 255\./;
			push(@dhcpnw,$1);
			#特定の文字列に囲まれたの中身をリストの最後に格納
			}
		}
	}
}
print TEST "@dhcpnw
";

my $length = @vrf;

print "要素数 $length
";

my $length = @dhcpnw;

print "要素数 $length
";


close FH;

#複数テナントが収容されている場合にDHCPを見分ける処理

for ($z = 0; $z <= $j;$z++){
#vrfの名前でファイルの検索を行う。
	foreach my $filename (@filename) {
	#ファイル分繰り返し処理を実行
		open FH, $filename or die $!;	
		while ($data = <FH>) {
				if($data =~ /ip dhcp pool/) {
					$flagD = 1;
					#特定行でフラグを建てる	
				}
				if($flagD == 1){
					if ($data =~ /vrf $vrfs[$z]$/) {
						$flagDv = 1;
						#特定vrfのDHCP設定のみフラグを建てる。
					}
				}
				if($flagDv == 1){
					if ($data =~ /${dhcpnw[$z]}/) {
						$flagDN = 1;
						#特定vrfの特定NWのみDHCP設定のみフラグを建てる。
					}
				}	
				if($data =~ /lease/){
					$flagD = 0;
					$flagDv = 0;
					$flagDN = 0;
					#特定行でフラグを削除
				}
				if($flagDN == 1){
					if ($data =~ /default-router/) {
					#フラグがある状態で特定行がある場合は処理
					$buf = $data;
					$buf =~ s/\s*$//;
					$buf =~ /default-router /;
					push(@dgw,$');
					#特定の文字列に囲まれたの中身をリストの最後に格納
				}
			}
		}
	}
}

my $length = @dgw;

print "要素数 $length
";

print TEST "@dgw
";
print TEST "@vrfs
";
print TEST "@dhcpnw
";



for ($i = 0,$v = 1402,$u = 1; $i <= $j;$i++,$v++,$u++){
#$vはvlan id(サブインターフェイス番号も兼用)
#$uはvrf番号(tunnel番号と兼用)
	print B "
vrf definition User${u}
 address-family ipv4
 exit-address-family

interface Tunnel${u}
 description ${vrf[$i]}
 vrf forwarding User${u}
 ip address ${ptuv4addr[$i]} 255.255.255.252
 ip mtu 1460
 tunnel source Loopback${u}
 tunnel mode ipv6
 tunnel destination ${tunsrc[$i]}
 tunnel path-mtu-discovery

interface Loopback${u}
 description ${vrf[$i]}
 no ip address
 ipv6 address ${tundest[$i]}/64

interface GigabitEthernet0/0/1.${v}
 description ${vrf[$i]}
 vrf forwarding User${u}
 encapsulation dot1Q ${v}
 ip address ${dgw[$i]} 255.255.255.0
 ip helper-address ${tuv4addr[$i]}

ip route vrf User${u} 0.0.0.0 0.0.0.0 ${tuv4addr[$i]}
";
}
#print @filename;
#print @tuv4addr;
#print @ptuv4addr;
#print @tundest;
#print $giv6addr;
#print @dgw;
#デバッグ用print
close FH;
close B;

close TEST;
#デバッグ用ファイル