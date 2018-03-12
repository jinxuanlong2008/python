#
# VRF���͏d�����Ă��Ȃ����Ƃ��O��ƂȂ��Ă���B
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
#debug�p�t�@�C��

$flagT = 0;
#Tunnel�C���^�[�t�F�C�X���̐ݒ�𔻕ʂ��邽�߂̕ϐ�
$flagG2 = 0;
#Gi2�C���^�[�t�F�C�X���̐ݒ�𔻕ʂ��邽�߂̕ϐ�
$flagr = 0;
#ip route���̐ݒ�𔻕ʂ��邽�߂̕ϐ�
$flagD = 0;
#DHCP�v�[�����̐ݒ�𔻕ʂ��邽�߂̕ϐ�
$flagDv = 0;
#�����vrf��DHCP�v�[�����̐ݒ�𔻕ʂ��邽�߂̕ϐ�

$path = "C:/Users/nwrd/Desktop/cisco�R���t�B�O/*";
#�R���t�B�O�ɓ����Ă���t�H���_�����w��
my @filename = glob($path);

open B,'> pCPE_config.txt';

foreach my $filename (@filename) {
#�t�@�C�����J��Ԃ����������s
	open FH, $filename or die $!;	
	$flagTa = 0;
	#��ԏ��߂�Tunnel�C���^�[�t�F�C�X�̂ݏ������邽�߂̕ϐ�
	#�t�@�C�����Ƃ�0�ɖ߂�
	
	while ($data = <FH>) {
		chomp $data;
		if($data =~ /interface Tunnel/) {
			$flagT = 1;
			#����s�Ńt���O�����Ă�
		}
		if($data eq " tunnel path-mtu-discovery"){
			$flagT = 0;
			#����s�Ńt���O���폜
		}
		if($data eq "interface GigabitEthernet2") {
			$flagG2 = 1;
			#����s�Ńt���O�����Ă�
		}
		if($data eq "service-policy output IPv6-U-Plane"){
			$flagG2 = 0;
			#����s�Ńt���O���폜
		}
		if($flagT == 1){
		#Tunnel�C���^�[�t�F�C�X���ϐ����o
			if ($data =~ /ip address/) {
			#�t���O�������Ԃœ���s������ꍇ�͏���
			$buf = $data;
			$buf =~ /address (.+) 255\.255\.255\.252/;
			push(@tuv4addr,$1);
			#����̕�����Ɉ͂܂ꂽ�̒��g�����X�g�̍Ō�Ɋi�[
			$tunnelnum = $tunnelnum+1;
			#tunnel�̐���ϐ��Ɋi�[
			}
			if ($data =~ /tunnel destination/) {
			$buf = $data;
			$buf =~ /destination /;
			push(@tundest,$');
			#����̕�����Ɉȍ~�����X�g�̍Ō�Ɋi�[
			}
			if ($data =~ /vrf forwarding/) {
			$buf = $data;
			$buf =~ /forwarding /;
			push(@vrf,$');
			#����̕�����Ɉȍ~�����X�g�̍Ō�Ɋi�[
			}
		}
		if($flagG2 == 1){
			if ($data =~ /ipv6 address/) {
			#�t���O�������Ԃœ���s������ꍇ�͏���
			$buf = $data;
			$buf =~ /address (.+)\/64/;
			push(@giv6addr,$1);
			#����̕�����Ɉ͂܂ꂽ�̒��g�����X�g�̍Ō�Ɋi�[
			}
		}
	}
	push(@tnum,$tunnelnum);
	#vCPE�̃g���l���̐������X�g�Ɋi�[
	$tunnelnum = 0;
	#�g���l���̐����i�[����ϐ���0�ɖ߂��B
}
close FH;

$u = 0;

foreach my $tnum (@tnum) {
	for ($i = 0;$i < $tnum;$i++){
	push(@tunsrc,$giv6addr[$u]);
	#�쐬�����A�h���X�����X�g�̍Ō�Ɋi�[
	}
	$u = $u+1;
}

my $length = @tuv4addr;

print "�v�f�� $length
";

foreach my $tuv4addr (@tuv4addr) {
	@bufl = split(/\./,$tuv4addr);
	$buf = @bufl[3] - 1;
	#vCPE��tunnel��v4�A�h���X����ApCPE��tunnel��v4�A�h���X����鏈��
	push(@ptuv4addr,join '.', @bufl[0], @bufl[1], @bufl[2], $buf);
	#�쐬�����A�h���X�����X�g�̍Ō�Ɋi�[
}
my $length = @ptuv4addr;

print "�v�f�� $length
";


foreach my $vrf (@vrf) {
	$buf = $vrf;
	$buf =~ s/\_/\\\_/g;
	#vrf�������p��vrf���ɃG�X�P�[�v������ǉ����鏈��
	push(@vrfs,$buf);
}

$j=@tuv4addr-1;
#�z��̗v�f�����擾;
for ($z = 0; $z <= $j;$z++){
	foreach my $filename (@filename) {
	#�t�@�C�����J��Ԃ����������s
		open FH, $filename or die $!;
		while ($data = <FH>) {
			chomp $data;
			#vrf�̖��O�Ńt�@�C���̌������s���B
			if($data =~ /ip route vrf $vrfs[$z] / and $data =~ /$ptuv4addr[$z]$/) {
			$buf = $data;
			print TEST "$data
";
			$buf =~ /ip route vrf $vrfs[$z] (.+) 255\./;
			push(@dhcpnw,$1);
			#����̕�����Ɉ͂܂ꂽ�̒��g�����X�g�̍Ō�Ɋi�[
			}
		}
	}
}
print TEST "@dhcpnw
";

my $length = @vrf;

print "�v�f�� $length
";

my $length = @dhcpnw;

print "�v�f�� $length
";


close FH;

#�����e�i���g�����e����Ă���ꍇ��DHCP���������鏈��

for ($z = 0; $z <= $j;$z++){
#vrf�̖��O�Ńt�@�C���̌������s���B
	foreach my $filename (@filename) {
	#�t�@�C�����J��Ԃ����������s
		open FH, $filename or die $!;	
		while ($data = <FH>) {
				if($data =~ /ip dhcp pool/) {
					$flagD = 1;
					#����s�Ńt���O�����Ă�	
				}
				if($flagD == 1){
					if ($data =~ /vrf $vrfs[$z]$/) {
						$flagDv = 1;
						#����vrf��DHCP�ݒ�̂݃t���O�����Ă�B
					}
				}
				if($flagDv == 1){
					if ($data =~ /${dhcpnw[$z]}/) {
						$flagDN = 1;
						#����vrf�̓���NW�̂�DHCP�ݒ�̂݃t���O�����Ă�B
					}
				}	
				if($data =~ /lease/){
					$flagD = 0;
					$flagDv = 0;
					$flagDN = 0;
					#����s�Ńt���O���폜
				}
				if($flagDN == 1){
					if ($data =~ /default-router/) {
					#�t���O�������Ԃœ���s������ꍇ�͏���
					$buf = $data;
					$buf =~ s/\s*$//;
					$buf =~ /default-router /;
					push(@dgw,$');
					#����̕�����Ɉ͂܂ꂽ�̒��g�����X�g�̍Ō�Ɋi�[
				}
			}
		}
	}
}

my $length = @dgw;

print "�v�f�� $length
";

print TEST "@dgw
";
print TEST "@vrfs
";
print TEST "@dhcpnw
";



for ($i = 0,$v = 1402,$u = 1; $i <= $j;$i++,$v++,$u++){
#$v��vlan id(�T�u�C���^�[�t�F�C�X�ԍ������p)
#$u��vrf�ԍ�(tunnel�ԍ��ƌ��p)
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
#�f�o�b�O�pprint
close FH;
close B;

close TEST;
#�f�o�b�O�p�t�@�C��