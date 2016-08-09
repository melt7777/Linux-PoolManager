#!/usr/bin/perl
#    This file is part of IFMI PoolManager.
#
#    PoolManager is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#

use warnings;
use strict;
use CGI qw(:cgi-lib :standard);
use feature qw(switch);
use YAML qw( DumpFile );

require '/opt/ifmi/pm-common.pl';
my $conf = &getConfig;
my %conf = %{$conf};
my $conffile = "/opt/ifmi/poolmanager.conf";

# Take care of business
&ReadParse(our %in);

my $ackgpu = $in{'ackbad'};
if (defined $ackgpu) {
	`rm /opt/ifmi/gpucountbad`;
	$ackgpu = "";
}

my $zreq = $in{'zero'};
if (defined $zreq) {
  &zeroStats;
  $zreq = "";
}

my $preq = $in{'swpool'};
if (defined $preq) {
  &switchPool($preq);
  &resetPoolSuperPri;
  $preq = "";
}

my $apoolr = $in{'npoolurl'};
my $apoolu = $in{'npooluser'};
my $apoolp = $in{'npoolpw'};
my $apooln = $in{'npoolname'};
my $apoold = $in{'npooldesc'};
my $apoolpr = $in{'setprof'};
my $apoola = $in{'npoolalgo'};
if (defined $apoolr) {
  my $pmatch = 0;
  my @pools = &getCGMinerPools(1);
  if (@pools) {
    for (my $i=0;$i<@pools;$i++) {
      my $pname = ${$pools[$i]}{'url'};
      my $pusr = ${$pools[$i]}{'user'};
      $pmatch++ if ($pname eq $apoolr && $pusr eq $apoolu);
    }
  }
  if ($pmatch eq 0) {
    &addPool($apoolr, $apoolu, $apoolp, $apooln, $apoold, $apoolpr, $apoola);
    &saveConfig();
    $apoolr = ""; $apoolu = ""; $apoolp = ""; $apooln = ""; $apoold = ""; $apoolpr = ""; $apoola = "";
  }
}
my $dpool = $in{'delpool'};
if (defined $dpool) {
  &delPool($dpool);
  &saveConfig();
  $dpool = "";
}

my $mstop = $in{'mstop'};
if (defined $mstop) {
	&stopCGMiner();
  $mstop = "";
}

my $mstart = $in{'mstart'};
if (defined $mstart) {
  `sudo /opt/ifmi/mcontrol start`;
  $mstart = "";
}
my $restart = $in{'startnm'};
if (defined $restart) {
	&stopCGMiner();
	my $snmc = $in{'startnm'};
	${$conf}{settings}{current_mconf} = $snmc;
	DumpFile($conffile, $conf);
	$snmc = "";
	sleep 3;
	`sudo /opt/ifmi/mcontrol start`;
}

my $reboot = $in{'reboot'};
if (defined $reboot) {
  `sudo /opt/ifmi/mcontrol boot`;
}

my $qval = $in{'qval'};
if (defined $qval) {
  my $qpool = $in{'qpool'};
  &quotaPool($qpool, $qval);
  &saveConfig();
  $qval = ""; $qpool = "";
}

my $gdig = $in{'gdig'};
if (defined $gdig) {
 &setGPUDisable($gdig);
 &saveConfig();
 $gdig = "";
}

my $geng = $in{'geng'};
if (defined $geng) {
 &setGPUEnable($geng);
 &saveConfig();
 $geng = "";
}

my $chstrat = $in{'setstrat'};
my $stratint = $in{'stratint'};
if (defined $chstrat) {
	print "STRATEGY: $chstrat\n";
 &changeStrategy($chstrat, $stratint);
# &saveConfig();
 $chstrat = "";
}

my $ncmc = $in{'setmconf'};
if (defined $ncmc) {
	${$conf}{settings}{current_mconf} = $ncmc;
	DumpFile($conffile, $conf);
	$ncmc = "";
}

my $npalias = $in{'npalias'};
if (defined $npalias) {
	my $paurl = $in{'paurl'};
	my $acount = 0;
  for (keys %{$conf{pools}}) {
		if ($paurl eq ${$conf}{pools}{$_}{url}) {
			${$conf}{pools}{$_}{alias} = $npalias;
			$acount++;
		}
	}
	if ($acount == 0) {
		my $newa = (keys %{$conf{pools}}); $newa++;
		${$conf}{pools}{$newa}{alias} = $npalias;
		${$conf}{pools}{$newa}{url} = $paurl;
	}
	DumpFile($conffile, $conf);
	$npalias = ""; $paurl = "";
}

my $npn = $in{'pnotify'};
if (defined $npn) {
	my $paurl = $in{'paurl'};
	my $acount = 0;
  for (keys %{$conf{pools}}) {
		if ($paurl eq ${$conf}{pools}{$_}{url}) {
			${$conf}{pools}{$_}{pnotify} = $npn;
			$acount++;
		}
	}
	if ($acount == 0) {
		my $newa = (keys %{$conf{pools}}); $newa++;
		${$conf}{pools}{$newa}{pnotify} = $npn;
		${$conf}{pools}{$newa}{url} = $paurl;
	}
	DumpFile($conffile, $conf);
	$npn = "";
}

my $prl = $in{'pnotifyl'};
if ((defined $prl) && ($prl ne "")) {
	my $paurl = $in{'paurl'};
	my $acount = 0;
  for (keys %{$conf{pools}}) {
		if ($paurl eq ${$conf}{pools}{$_}{url}) {
			${$conf}{pools}{$_}{pool_reject_hi} = $prl;
			$acount++;
		}
	}
	if ($acount == 0) {
		my $newa = (keys %{$conf{pools}}); $newa++;
		${$conf}{pools}{$newa}{pool_reject_hi} = $prl;
		${$conf}{pools}{$newa}{url} = $paurl;
	}
	DumpFile($conffile, $conf);
	$prl = "";
}

my $rpri = $in{'rpri'};
	if (defined $rpri) {
	&setPoolSuperPri($rpri);
}


my $uapname = $in{'uapname'};
my $uapa = $in{'uapa'};
my $uapi = $in{'uapi'};
my $uaptc = $in{'uaptc'};
my $uaplg = $in{'uaplg'};
my $uapeng = $in{'uapeng'};
my $uapmem = $in{'uapmem'};
my $uapthr = $in{'uapthr'};
my $uapfan = $in{'uapfan'};
my $uappt = $in{'uappt'};
my $uapws = $in{'uapws'};
if (defined $uapname) {
    &updateAProfile($uapname, $uapa, $uapi, $uaptc, $uaplg, $uapeng, $uapmem, $uapthr, $uapfan, $uappt, $uapws);
    &saveConfig();
}

my $delap = $in{'delap'};
if (defined $delap) {
	&deleteAProfile($delap);
  &saveConfig();
}

# Now carry on

my $miner_name = `hostname`;
chomp $miner_name;
my $iptxt;
my $nicget = `/sbin/ifconfig`;
  while ($nicget =~ m/(\w\w\w?\w?\d)\s.+\n\s+inet addr:(\d+\.\d+\.\d+\.\d+)\s/g) {
  $iptxt = $2;
}

my $q=CGI->new();

my $showgpu = -1;
my $showpool = -1;
my $showminer = -1;

if (defined($q->param('gpu')))
{
	$showgpu = $q->param('gpu');
}
if (defined($q->param('pool')))
{
	$showpool = $q->param('pool');
}
if (defined($q->param('miner')))
{
	$showminer = 0;
}

my $url = "?";

if ($showgpu > -1)
{
	$url .= "gpu=$showgpu&";
}
if ($showpool > -1)
{
	$url .= "pool=$showpool&";
}
if ($showminer > -1)
{
	$url .= "miner=$showminer&";
}

print header;
if ($url eq "?")
{
	print start_html( -title=>'PM - ' . $miner_name . ' - Status',
		-style=>{-src=>'/IFMI/themes/' . $conf{display}{status_css}},
		-head=>$q->meta({-http_equiv=>'REFRESH',-content=>'30'})
		);
}
else
{
	$url .= "tok=1";
	print start_html( -title=>'PM - ' . $miner_name . ' - Status',
		-style=>{-src=>'/IFMI/themes/' . $conf{display}{status_css}},
		-head=>$q->meta({-http_equiv=>'REFRESH',-content=>'30; url=' . $url })
	  );
}

# pull info
my $version = &getCGMinerVersion;
my $ispriv = &CGMinerIsPriv;
my @gpus = &getFreshGPUData(1);
my @pools = &getCGMinerPools(1);
my @summary = &getCGMinerSummary;
my @mconfig = &getCGMinerConfig;
my @profiles = &getCGMinerProfiles;
my $UHOH = "false";
$UHOH = "true" if (!(@pools) && !(@summary) && !(@gpus));

# do GPUs
my $gput; my $g1put; my $gsput; my $ggimg; my $atable;
my @nodemsg; my @gpumsg;
my $problems = 0;
my $okgpus = 0;
my $problemgpus = 0;

if (@gpus) {
	$g1put .= "<TABLE id='gpucontent'>";
	$g1put .= "<tr><h3 class='section_header' align='left'>GPUS:</h3></tr>";
	$g1put .= "<TR class='header'><TD class='header'>GPU</TD>";
	$g1put .= "<TD class='header'>Status</TD>";
	$g1put .= "<TD class='header'>Temp</TD>";
	$g1put .= "<TD class='header'>Fan</TD>";
	$g1put .= "<TD class='header'>Rate</TD>";
	$g1put .= "<TD class='header'>Pool</TD>";
	$g1put .= "<TD class='header' colspan=2>Accept/Reject</TD>";
	$g1put .= "<TD class='header'>I</TD>";
	$g1put .= "<TD class='header'>HW</TD>";
	$g1put .= "<TD class='header'>Core</TD>";
	$g1put .= "<TD class='header'>Memory</TD>";
	$g1put .= "<TD class='header'>Power</TD></tr>";

	for (my $i=0;$i<@gpus;$i++) {
	  my $gput;
		if ($i == $showgpu) {
	  	my $gpudesc = $gpus[$i]{'desc'};
	  	if (defined $gpudesc) {
		  		$gsput .= "<tr><td>GPU model:</td><td colspan=3>$gpudesc</td></tr>";
			} else {
		  		$gsput .= "<tr><td>GPU model:</td><td colspan=3>Unknown</td></tr>";
			}
		}

	  my $ghealth = $gpus[$i]{'status'};
	  if ($ghealth ne "Alive") {
			$problems++;
			push(@nodemsg, "GPU $i is $ghealth");
			if ($i == $showgpu) {
				push(@gpumsg, "$ghealth");
				$gsput .= "<tr><td>Status:</td><td class='error'>$ghealth</td>";
			}
		}	else {
			if ($i == $showgpu) {
				$gsput .= "<tr><td>Status:</td><td>$ghealth</td>";
			}
	 	}

		if ($i == $showgpu) {
			if ($gpus[$i]{'enabled'} eq "Y") {
		    $gsput .= "<td>Enabled</td>";
			  $gsput .= "<td><form name='gdisable' method='POST'>";
			  $gsput .= "<input type='hidden' name='gdig' value='$i'>";
			  $gsput .= "<input type='submit' value='Disable'> ";
			} else {
		    $gsput .= "<td>Disabled</td>";
			  $gsput .= "<td><form name='genable' method='POST'>";
			  $gsput .= "<input type='hidden' name='geng' value='$i'>";
			  $gsput .= "<input type='submit' value='Enable'> ";
			}
	    $gsput .= "</form></td></tr>";
		}

		if ($gpus[$i]{'current_temp_0_c'} > $conf{monitoring}{monitor_temp_hi})
		{
				$problems++;
				push(@nodemsg, "GPU $i is over maximum temp");

				if ($i == $showgpu)
				{
					push(@gpumsg, "Over maximum temp");
					$gsput .= "<tr><td>Temp:</td><td class='error'>" . sprintf("%.1f", $gpus[$i]{'current_temp_0_c'}) . 'C</td>';
				}

				$gput .= "<td class='error'>";
		}
		elsif ($gpus[$i]{'current_temp_0_c'} < $conf{monitoring}{monitor_temp_lo})
		{
				$problems++;
				push(@nodemsg, "GPU $i is below minimum temp");

				if ($i == $showgpu)
				{
					push(@gpumsg, "Below minimum temp");
					$gsput .= "<tr><td>Temp:</td><td class='error'>" . sprintf("%.1f", $gpus[$i]{'current_temp_0_c'}) . ' C</td>';
				}

				$gput .= "<td class='error'>";
		}
		else
		{
			if ($i == $showgpu)
			{
				$gsput .= "<tr><td>Temp:</td><td>" . sprintf("%.1f", $gpus[$i]{'current_temp_0_c'}) . ' C</td>';
			}
			$gput .= '<td>';
		}
		$gput .= sprintf("%.1f", $gpus[$i]{'current_temp_0_c'}) . ' C</td>';

		my $frpm = "0"; $frpm = $gpus[$i]{'fan_rpm_c'};
		if ($frpm < ($conf{monitoring}{monitor_fan_lo}) && ($frpm > 0))
		{
			$problems++;
			push(@nodemsg, "GPU $i is below minimum fan RPM");

			if ($i == $showgpu)
			{
				push(@gpumsg, "Below minimum fan RPM");
				$gsput .= "<td>Fan speed:</td><td class='error'>" .  $gpus[$i]{'fan_speed_c'} . '% (' . $gpus[$i]{'fan_rpm_c'}  . " rpm)</td></tr>";
			}

			$gput .= "<td class='error'>";
		}
		elsif ($frpm > ($conf{monitoring}{monitor_fan_hi}))
		{
			$problems++;
			push(@nodemsg, "GPU $i is above maximum fan RPM");

			if ($i == $showgpu)
			{
				push(@gpumsg, "Above maximum fan RPM");
				$gsput .= "<td>Fan speed:</td><td class='error'>" .  $gpus[$i]{'fan_speed_c'} . '% (' . $gpus[$i]{'fan_rpm_c'}  . " rpm)</td></tr>";
			}

			$gput .= "<td class='error'>";
		}
		else
		{
			if ($i == $showgpu)
			{
					$gsput .= "<td>Fan speed:</td><td>" .  $gpus[$i]{'fan_speed_c'} . '% ';
					if ($frpm > 0) {
					  $gsput .= '(' . $gpus[$i]{'fan_rpm_c'}  . ' rpm)';
					}
					$gsput .= "</td></tr>";
			}

			$gput .= '<td>';
		}
		$gput .= $gpus[$i]{'fan_speed_c'} . '% ';
		if ($frpm > 0) {
		  $gput .= '(' . $gpus[$i]{'fan_rpm_c'} . ')';
		}
		$gput .= '</TD>';

		my $ghashrate = $gpus[$i]{'hashrate'};
		$ghashrate = $gpus[$i]{'hashavg'} if ($ghashrate eq "");
		$ghashrate = $gpus[$i]{'hashavg'} if ($conf{display}{usehashavg} >0);
		if ($ghashrate < $conf{monitoring}{monitor_hash_lo})
		{
			$problems++;
			push(@nodemsg, "GPU $i is below minimum hash rate");
			if ($i == $showgpu)
			{
				push(@gpumsg, "Below minimum hash rate");
			}
			$gput .= "<td class='error'>";
		}
		else
		{
			$gput .= '<td>';
		}
		$gput .= sprintf("%d", $ghashrate) . " Kh/s</TD>";

			my $shorturl;
	    my $poolurl = $gpus[$i]{'pool_url'};
	    if ((defined $poolurl) && ($poolurl =~ m/.+\@(.+)/)) {
	      $poolurl = $1;
	    }
	    if ((defined $poolurl) && ($poolurl =~ m|://(\w+-?\w+\.)+?(\w+-?\w+\.\w+:\d+)|)) {
	       $shorturl = $2;
	    }
	 	$shorturl = "N/A" if (! defined $shorturl);
	    if ($i == $showgpu) {
	        $gsput .= "<tr><td>Pool:</td><td colspan=3>" . $poolurl  . "</td>";
	    }
		$gput .= "<td>" . $shorturl . "</td>";


		my $gsha = $gpus[$i]{'shares_accepted'}; $gsha = 0 if ($gsha eq "");
		my $gshi = $gpus[$i]{'shares_invalid'}; $gshi = 0 if ($gshi eq "");
		$gput .= '<TD>' . $gsha . " / " . $gshi . '</TD>';
		if ($gsha > 0)
		{
			my $rr = $gpus[$i]{'shares_invalid'}/($gpus[$i]{'shares_accepted'} + $gpus[$i]{'shares_invalid'})*100 ;
			if ($rr > ${$conf}{monitoring}{monitor_reject_hi})
			{
				$problems++;
				push(@nodemsg, "GPU $i is above maximum reject rate");
				if ($i == $showgpu)
				{
					push(@gpumsg, "Above maximum reject rate");
			        $gsput .= "<tr><td>Total MH:</td><td>" . $gpus[$i]{'total_mh'} . "</td>";
					$gsput .= "<td>Shares A/R:</td><td class='error'>" .  $gpus[$i]{'shares_accepted'} . ' / ' . $gpus[$i]{'shares_invalid'} . ' (' . sprintf("%-2.2f%", $rr) . ")</td></tr>";
				}
				$gput .= "<td class='error'>";
			}
			else
			{
				if ($i == $showgpu)
				{
			    $gsput .= "<tr><td>Total MH:</td><td>" . $gpus[$i]{'total_mh'} . "</td>";
					$gsput .= "<td>Shares A/R:</td><td>" .  $gpus[$i]{'shares_accepted'} . ' / ' . $gpus[$i]{'shares_invalid'} . ' (' . sprintf("%2.2f%%", $rr) . ")</td></tr>";
				}
				$gput .= '<td>';
			}
			$gput .= sprintf("%2.2f%%", $rr);
		}
		else
		{
			if ($i == $showgpu)
			{
					$gsput .= "<tr><td>Shares A/R:</td><td>" .  $gpus[$i]{'shares_accepted'} . ' / ' . $gpus[$i]{'shares_invalid'} . "</td></tr>";
			}

			$gput .= '<td>N/A';
		}
		$gput .= "</TD>";

		my $gint = $gpus[$i]{'intensity'};
		my $gxint = $gpus[$i]{'xintensity'};
		$gint = "x" . $gxint if ($gxint ne "" && $gxint > 0);
		$gput .= '<TD>' . $gint . '</td>';

		my $gpuhwe;
	  my $ghwe = $gpus[$i]{'hardware_errors'};
		if ($ghwe > 0) {
		  $problems++;
		  push(@nodemsg, "GPU $i has hardware errors");
		  if ($i == $showgpu) {
			push(@gpumsg, "Hardware errors");
		  }
		  $gpuhwe = "<td class='error'>" . $ghwe . "</td>";
		} else {
		  $ghwe = "N/A" if ($ghwe eq "");
		  $gpuhwe = "<td>" . $ghwe . "</td>";
		}
	    $gput .= $gpuhwe;

		my $gccc = $gpus[$i]{'current_core_clock_c'}; $gccc = "0" if ($gccc eq "");
		$gput .= '<TD>' . $gccc . ' Mhz</td>';

		my $gcmc = $gpus[$i]{'current_mem_clock_c'}; $gcmc = "0" if ($gcmc eq "");
		$gput .= '<TD>' . $gcmc . ' Mhz</td>';

		my $gccv = $gpus[$i]{'current_core_voltage_c'}; $gccv = "0" if ($gccv eq "");
		$gput .= '<TD>' . $gccv . 'v</td>';

		$gput .= "</TR>";

		my $gpuload;
		if ($gpus[$i]{'current_load_c'} < $conf{monitoring}{monitor_load_lo})
		{
			$problems++;
			push(@nodemsg, "GPU $i is below minimum load");
			$gpuload = "<td class='error'>" . $gpus[$i]{'current_load_c'}  ."%</td>";
			push(@gpumsg, "Below minimum load");
		} else {
			$gpuload = "<td>" . $gpus[$i]{'current_load_c'}  . "%</td>";
	 	}

		if ($i == $showgpu)
		{
			$gsput .= "<tr><td>Load:</td>" . $gpuload;

	        push(@gpumsg, "GPU $i has Hardware Errors") if ($ghwe > 0);
			$gsput .= "<td>HW Errors:</td>" . $gpuhwe . "</tr>";

	        $gsput .= "<tr><td>Intensity:</td><td>" . $gpus[$i]{'intensity'} . "</td>";
	        $gsput .= "<td>Powertune:</td><td>" . $gpus[$i]{'current_powertune_c'} . "%</td></tr>";

			$gsput .= "<tr><td>Core clock:</td><td>" . $gccc . ' Mhz</td>';
			$gsput .= "<td>Mem clock:</td><td>" . $gcmc . ' Mhz</td></tr>';
			$gsput .= "<tr><td>Core power:</td><td>" . $gccv . "v</td></tr>";
			$ggimg = "<br><img src='/IFMI/graphs/gpu$i.png'>";
		}

		my $gpuurl = "?";

		$gpuurl .= "gpu=$i";

		if ($problems)
		{
			$gput = '<TR><TD class="bigger"><A href="' . $gpuurl . '">' . $i . '</TD><TD class=error><img src=/IFMI/error24.png></td>' . $gput;
			$problemgpus++;
		}
		else
		{
			$gput = '<TR><TD class="bigger"><A href="' . $gpuurl . '">' . $i . '</TD><TD><img src=/IFMI/ok24.png></td>' . $gput;
			$okgpus++;
		}
		$g1put .= $gput;
		$problems = 0;
	}
	$g1put .= "</table>";
}

my $mstrategy; my $mfonly; my $mscant; my $mqueue; my $mexpiry; my $mineri; my $mswdelay;
if (@mconfig) {
	for (my $i=0;$i<@mconfig;$i++) {
		$mstrategy = ${$mconfig[0]}{'strategy'};
		$mfonly = ${$mconfig[0]}{'fonly'};
		$mscant = ${$mconfig[0]}{'scantime'};
		$mqueue = ${$mconfig[0]}{'queue'};
		$mexpiry = ${$mconfig[0]}{'expiry'};
		$mineri = ${$mconfig[0]}{'rotate_int'};
		$mswdelay = ${$mconfig[0]}{'sw_delay'};
	}
}

my $mcontrol;
$mcontrol .= "<table id='mcontrol'><tr>";
my $surl = "?"; $surl .= 'miner=$i';
$mcontrol .= '<TD class="bigger"><A href="' . $surl . '">Edit Miner Profile</a></td>';
my $mvers = "CGMiner "; my $avers;
if ($version =~ m/(\d+\.\d+\.\d+),API=(\d+\.\d+)/) {
	$mvers .= $1;
  $avers = $2;
}
if ($version =~ m/,Miner=(.+?),/){
		$mvers = $1;
}
my $getmlinv; my $mlinv; my $msput; my $minerate; my $mineacc; my $minerej; my $minewu; my $minehe;
my $melapsed;
if (@summary) {
  for (my $i=0;$i<@summary;$i++) {
    $melapsed = ${$summary[$i]}{'elapsed'};
    my $mrunt = sprintf("%d days, %02d:%02d.%02d",(gmtime $melapsed)[7,2,1,0]) if (defined $melapsed);
    my $mratem = ${$summary[$i]}{'hashrate'};
    $mratem = ${$summary[$i]}{'hashavg'} if (!defined $mratem);
    $mratem = ${$summary[$i]}{'hashavg'} if ($conf{display}{usehashavg} >0 );
    $minerate = sprintf("%.2f", $mratem) if (defined $mratem);
    $mineacc = ${$summary[$i]}{'shares_accepted'};
    $minerej = ${$summary[$i]}{'shares_invalid'};
    $minewu = ${$summary[$i]}{'work_utility'};
    $minehe = ${$summary[$i]}{'hardware_errors'};
    my $currentm = $conf{settings}{current_mconf};
 		my $currname = $conf{miners}{$currentm}{mconfig};
 		my $runningm	= $conf{settings}{running_mconf};
 		my $runname = $conf{miners}{$runningm}{mconfig};
  	if ($showminer == $i) {
	  	$msput .= "<tr><td colspan=4 class=big>Miner</td></tr>";
	  	my $pimpver = `cat /etc/version` if (-e "/etc/version");
	  	$pimpver =~ s/\n//g if (defined $pimpver);
	  	$msput .= "<tr><td>PiMP Version: </td><td>$pimpver</td>" if (defined $pimpver);
	  	if (defined $mvers) {
		  	$msput .= "<tr><td>Miner Version: </td><td>$mvers (API: $avers)</td></tr>";
		 		$msput .= "<tr><td>Mining Strategy: </td><td>$mstrategy ";
		 		if ($mstrategy eq "Rotate") {
		 			$msput .= "(interval: $mineri)</td>";
		 		} else {
		 			$msput .= "(switch delay: $mswdelay)</td>";
		 		}
		 	}
		 	if ($avers >= 4) {
				$msput .= "<td colspan=2><form name='mstrategy' method='post'><select name='setstrat'>";
				$msput .= "<option value='0'>Failover</option>";
				$msput .= "<option value='1'>Rnd Robin</option>";
				$msput .= "<option value='2'>Rotate</option>";
				$msput .= "<option value='3'>Load Bal</option>";
				$msput .= "<option value='4'>Balance</option></select>";
				$msput .= " (rotate int:<input type='text' size='5' placeholder='seconds' name='stratint'>)";
				$msput .= " <input type='submit' value='Select'>";
				$msput .= "</form></td></tr>";
			}
	 		$msput .= "<tr><td>Running Profile:  </td><td>$runname</td>";
	 		my $runpath = $conf{miners}{$runningm}{mpath};
	 		$msput .= "<td>Run Path: </td><td>$runpath</td></tr>";
	 		$msput .= "<tr><td>Loaded Profile:  </td><td>$currname</td>";
			$msput .= "<td colspan=2><form name=currentm method=post><select name=setmconf>";
			for (sort { $a <=> $b } keys %{$conf{miners}}) {
  			my $mname = $conf{miners}{$_}{mconfig};
  				if ($currentm eq $_) {
    				$msput .= "<option value=$_ selected>$mname</option>";
	  			} else {
  	  			$msput .= "<option value=$_>$mname</option>";
  				}
				}
			$msput .= "</select><input type='submit' value='Select'>";
			$msput .= "</form></td></tr>";

			my $currconf = $conf{miners}{$currentm}{savepath};
			$msput .= "<tr><td>Loaded Config:  </td><td colspan=3>";
	    $msput .= "<a href='/cgi-bin/confedit.pl'>";
			$msput .= "$currconf</a></td></tr>";
			$mrunt = "Stopped" if (!defined $mrunt);
	    $msput .= "<tr><td>Run time:</td><td>" . $mrunt . "</td>";
			if (defined $melapsed) {
			  $msput .= "<td  colspan=2><form name='mstop' action='status.pl' method='POST'><input type='hidden' name='mstop' value='stop'><input type='submit' value='Stop' onclick='this.disabled=true;this.form.submit();' > ";
			} else {
			  $msput .= "<td  colspan=2><form name='mstart' action='status.pl' method='POST'><input type='hidden' name='mstart' value='start'><input type='submit' value='Start' onclick='this.disabled=true;this.form.submit();' > ";
			}
			$msput .= "</form></tr>";
			$msput .= "</table><table>";
			if (defined $melapsed) {
				$msput .= "<tr><td colspan=4>Stats</td><tr>";
				my $mtm = ${$summary[$i]}{'total_mh'};
				my $minetm = sprintf("%.2f", $mtm);
		    $msput .= "<tr><td>Total MH:</td><td>" . $minetm . "</td>";
				my $minefb = ${$summary[$i]}{'found_blocks'};
				$minefb = 0 if (!defined $minefb);
	      $msput .= "<td>Found Blocks:</td><td>" . $minefb . "</td></tr>";
				my $minegw = ${$summary[$i]}{'getworks'};
				$minegw = 0 if (!defined $minegw);
	      $msput .= "<tr><td>Getworks:</td><td>" . $minegw . "</td>";
				my $minedis = ${$summary[$i]}{'discarded'};
	      $minedis = 0 if (!defined $minedis);
	      $msput .= "<td>Discarded:</td><td>" . $minedis . "</td></tr>";
				my $minest = ${$summary[$i]}{'stale'};
				$minest = 0 if (!defined $minest);
	      $msput .= "<tr><td>Stale:</td><td>" . $minest . "</td>";
				my $minegf = ${$summary[$i]}{'get_failures'};
				$minegf = 0 if (!defined $minegf);
	      $msput .= "<td>Get Failures:</td><td>" . $minegf . "</td></tr>";
				my $minerf = ${$summary[$i]}{'remote_failures'};
				$minerf = 0 if (!defined $minerf);
	      $msput .= "<tr><td>Remote Fails:</td><td>" . $minerf . "</td>";
				my $minenb = ${$summary[$i]}{'network_blocks'};
				$minenb = 0 if (!defined $minenb);
	      $msput .= "<td>Network Blocks:</td><td>" . $minenb . "</td></tr>";
	      my $mdia = ${$summary[$i]}{'diff_accepted'};
				my $minedia = sprintf("%d", $mdia);
	      $msput .= "<tr><td>Diff Accepted:</td><td>" . $minedia . "</td>";
	      my $mdir = ${$summary[$i]}{'diff_rejected'};
				my $minedir = sprintf("%d", $mdir);
	      $msput .= "<td>Diff Rejected:</td><td>" . $minedir . "</td></tr>";
	      my $mds = ${$summary[$i]}{'diff_stale'};
				my $mineds = sprintf("%d", $mds);
	      $msput .= "<tr><td>Difficulty Stale:</td><td>" . $mineds . "</td>";
				my $minebs = ${$summary[$i]}{'best_share'};
				$minebs = 0 if (!defined $minebs);
	      $msput .= "<td>Best Share:</td><td>" . $minebs . "</td></tr></table>";
	    }
			$msput .= "<table><tr><td colspan=4><hr></td></tr>";
	  	$msput .= "<tr><td colspan=4 class=big>Node</td></tr>";
  		$getmlinv = `cat /proc/version`;
  		$mlinv = $1 if ($getmlinv =~ /version\s(.*?\s+\(.*?\))\s+\(/);
     	$msput .= "<tr><td colspan=2>Linux Version: " . $mlinv . "</td>";
			$msput .= "<form name='reboot' action='status.pl' method='POST'><input type='hidden' name='reboot' value='reboot'>";
			$msput .= "<td colspan=2><input type='submit' value='Reboot' onclick='this.disabled=true;this.form.submit();' > ";
			$msput .= "</td></tr></form>";
  		$msput .= "<tr><td colspan=2>Host IP: $iptxt</td>";
			$msput .= '<td class=big colspan=2><A href=ssh://user@' . $iptxt . '>SSH to Host</a></td></tr>';
			$msput .= "<tr><td colspan=4><hr></td></tr>";
 			$msput .= "<tr><td class=big><a href='config.pl'>PoolManager Configuration</a></td><td>";

  	} else {
			if (defined $melapsed) {
				$mcontrol .= "<td>$mvers";
		  	$mcontrol .= "<br><small>$mstrategy Mode</small></td>";
			  $mcontrol .= "<td>Profile: $runname<br>";
		  	$mcontrol .= "<small>Run time: " . $mrunt . "</small></td>";
			  $mcontrol .= "<td><form name='mstop' action='status.pl' method='POST'><input type='hidden' name='mstop' value='stop'><input type='submit' value='Stop' onclick='this.disabled=true;this.form.submit();' > </form>";
			  $mcontrol .= "<td><small>Switch Miner Profile</small><br>";
				$mcontrol .= "<form name='startnm' action='status.pl' method='post'><select name='startnm'>";
				for (sort { $a <=> $b } keys %{$conf{miners}}) {
	  			my $mname = $conf{miners}{$_}{mconfig};
	  				if ($currentm eq $_) {
	    				$mcontrol .= "<option value=$_ selected>$mname</option>";
		  			} else {
	  	  			$mcontrol .= "<option value=$_>$mname</option>";
	  				}
					}
				$mcontrol .= "<input type='submit' value='Restart'>";
				$mcontrol .= "</select></form></td>";
			} else {
		  	$mcontrol .= "<td class='error'>Stopped</td>";
			  $mcontrol .= "<td><form name=currentm method=post>Profile: <select name=setmconf>";
				for (sort { $a <=> $b } keys %{$conf{miners}}) {
  				my $mname = $conf{miners}{$_}{mconfig};
  				if ($currentm eq $_) {
    				$mcontrol .= "<option value=$_ selected>$mname</option>";
	  			} else {
  	  			$mcontrol .= "<option value=$_>$mname</option>";
  				}
				}
				$mcontrol .= "<input type='submit' value='Select'>";
				$mcontrol .= "</select></form></td>";
			  $mcontrol .= "<td><form name='mstart' action='status.pl' method='POST'><input type='hidden' name='mstart' value='start'><input type='submit' value='Start' onclick='this.disabled=true;this.form.submit();' > </form>";
			}
			$mcontrol .= "</td>";
			#$mcontrol .=  "<td><A href=/cgi-bin/farmstatus.pl>Farm Overview</A></td>" if (-e "/usr/lib/cgi-bin/farmstatus.pl");
			$mcontrol .=  "<td><A href=/cgi-bin/seedstatus.pl>SeedManager (PoolManager for ASICs)</A></td>" if (-e "/usr/lib/cgi-bin/seedstatus.pl");
		}
  }
}
$mcontrol .= "</tr></table><br>";


#my $adata = `cat /tmp/adata`;
my $adata = "<div align='left'>GETTING STARTED: <br/>Choose a profile in the dropdown box above and then click Select. <br/>Then Click 'Edit Miner Profile' above to customize.</div>";
my $donate = "<div align='left'>Please donate to PiMP developers!<br/>BTC: 1BfFyiViCY18vvrhQuYwDzvYUkUsUZLhcX <br/>(or choose one of the PiMP testing Miner Profiles.)</div>";
$mcontrol .= "<table><td>$adata</td><td>$donate</td></table><br>";

if (-e "/opt/ifmi/gpucountbad") {
	my $badgpus = `cat /opt/pimp/gpudiff`; my $bgids;
	while ($badgpus =~ m/\s(\d)\./g) {
		$bgids .= "$1 ";
	}
	$mcontrol .= "<table><td class=error>WARNING: Current GPU Count is less than GPU Count at last boot. Missing GPU(s): $bgids\n";
	$mcontrol .= "If this is intentional please click Acknowledged to confirm.";
	$mcontrol .= "<form name='badgpu' method='POST'><input type='hidden' name='ackbad' value='ackbad'><input type='submit' value='Acknowledged - I have removed a GPU'> </form>";
	$mcontrol .= "If not, check your risers / power to verify all GPU's are functional.";
	$mcontrol .= "</td></table><br>";
}

my $p1sum; my $psum; my $psput; my @poolmsg; my $pgimg;
$p1sum .= "<table id='pcontent'>";

if ($ispriv eq "S") {
	$p1sum .= "<tr><h3 class='section_header' align='left'>POOLS:</h3></tr>";
	$p1sum .= "<TR class='header'><TD class='header'>Pool</TD>";
	$p1sum .= "<TD class='header'>Pool URL</TD>";
#	$p1sum .= "<TD class='header'>Alias</TD>";
	$p1sum .= "<TD class='header'>Worker</TD>" if ($avers > 1.16);
	$p1sum .= "<TD class='header'>Status</TD>";
	$p1sum .= "<TD class='header'>Algo Prof</TD>" if ($avers >= 4);
	$p1sum .= "<TD class='header' colspan=2>Accept/Reject</TD>";
	$p1sum .= "<TD class='header'>Active</TD>";
	$p1sum .= "<TD class='header' colspan=2>Priority</TD>" if ($mstrategy eq "Failover");
	$p1sum .= "<TD class='header' colspan=2>Quota (ratio or %)</TD>" if ($mstrategy eq "Load Balance");
	$p1sum .= "</TR>";
 	my @currorder;
	if (@pools) {
	  for (my $i=0;$i<@pools;$i++) {
			my $pimg = "<img src='/IFMI/timeout24.png'>";
	    $pimg = "<form name='pselect' action='status.pl' method='POST'><input type='hidden' name='swpool' value='$i'><button type='submit'>Switch</button></form>"
	    				if ($mstrategy eq "Failover");
    	my $pname = ${$pools[$i]}{'url'};
			my $pactive = 0;
			for (my $g=0;$g<@gpus;$g++) {
				my $gurl = $gpus[$g]{'pool_url'};
				if ((defined $pname) && (defined $gurl) && ($pname eq $gurl)) {
					$pactive++;
				}
			}
			$pimg = "<img src='/IFMI/ok24.png'>" if ($pactive >0);
	    my $pnum = ${$pools[$i]}{'poolid'};
	    my $pusr = ${$pools[$i]}{'user'};
	    my $pstat = ${$pools[$i]}{'status'};
	    my $pstatus;
	    if ($pstat eq "Dead") {
	      $problems++;
	      push(@nodemsg, "Pool $i is dead");
	      $pstatus = "<td class='error'>" . $pstat . "</td>";
	      $pimg = "<img src='/IFMI/error24.png'>";
		  	push(@poolmsg, "Pool is dead") if ($showpool == $i);
	    } else {
	      $pstatus = "<td>" . $pstat . "</td>";
	    }
	    my $ppri = ${$pools[$i]}{'priority'};
	    my $pacc = ${$pools[$i]}{'accepted'};
	    my $prej = ${$pools[$i]}{'rejected'};
	    my $prr;
	    if ($prej ne "0") {
	       $prr = sprintf("%.2f", $prej / ($pacc + $prej)*100);
	    } else {
		   $prr = "0.0";
	    }
	    my $prat;
	    my $pcname = ${$pools[$i]}{'name'};
	    my $pcdesc = ${$pools[$i]}{'descr'};
	   	my $poola; my $poolnum; my $spri;
      for (keys %{$conf{pools}}) {
      	if (defined ${$conf}{pools}{$_}{url} && $pname eq ${$conf}{pools}{$_}{url}) {
      		$poola = ${$conf}{pools}{$_}{alias};
      		$spri = ${$conf}{pools}{$_}{spri};
      		$poolnum = $_;
      	}
      }
			$poola = $pcname if (!defined $poola);
			$poola = "n/a"  if (!defined $poola);
      $poolnum = 0 if (!defined $poolnum);
      my $prhl = ${$conf}{pools}{$poolnum}{pool_reject_hi} if (defined ${$conf}{pools}{$poolnum}{pool_reject_hi});
			if ((defined $prhl) && ($prr > $prhl)) {
	      $problems++;
	      push(@nodemsg, "Pool $i reject ratio too high");
	  	  $prat = "<td class='error'>" . $prr . "%</td>";
	      push(@poolmsg, "Reject ratio is too high") if ($showpool == $i);
	    } else {
	      $prat = "<td>" . $prr . "%</td>";
	    }
	    my $pquo = ${$pools[$i]}{'quota'};
	    my $palgo = ${$pools[$i]}{'algo'};
	    my $palgt = ${$pools[$i]}{'algo_type'};
	    my $pprofile = ${$pools[$i]}{'profile'};

	    if ($showpool == $i) {
	    	my $current;
	      my $psgw = ${$pools[$i]}{'getworks'};
	      my $psw = ${$pools[$i]}{'works'};
	      my $psd = ${$pools[$i]}{'discarded'};
	      my $pss = ${$pools[$i]}{'stale'};
	      my $psgf = ${$pools[$i]}{'getfails'};
	      my $psrf = ${$pools[$i]}{'remotefailures'};
		  	if ($pactive >0) {
					$current = "Active";
	      } else {
					$current = "Not Active  ";
	      }
	      $psput .= "<tr><form name='pdelete' action='status.pl' method='POST'><td class='big' colspan=4>$current";
		  	if ($pactive == 0) {
	      	$psput .= "<input type='hidden' name='delpool' value='$i'><input type='submit' value='Remove this pool'>";
	      }
	      $psput .= "</form></td></tr>";
	      $psput .= "<tr><td>Mining URL:</td><td colspan=3>" . $pname . "</td></tr>";
				$psput .= "<tr><td>Alias:</td><td>$poola</td><td colspan=2>";
	      $psput .= "<form name='palias' action='status.pl' method='POST'>";
				$psput .= "<input type='text' size='10' placeholder='pool alias' name='npalias'>";
				$psput .= "<input type='hidden' name='paurl' value='$pname'>";
				$psput .= "<input type='submit' value='Change'></form></td></tr>";
			  $pusr = "unknown" if (!defined $pusr);
	      $psput .= "<tr><td>Worker:</td><td colspan=3>" . $pusr . "</td></tr>";
	      $psput .= "<tr><td>Status: $pstatus</td>";
	      $psput .= "<td>Notify when Dead?</td>";
		  	my $pnotify = $conf{pools}{$poolnum}{pnotify};
		  	$psput .= "<form name=pnotify method=post><input type=hidden name='paurl' value=$pname>";
		  	if ((defined $pnotify) && ($pnotify==1)) {
    	  	$psput .= "<td><input type='radio' name='pnotify' value=1 checked>Yes ";
    	  	$psput .= "<input type='radio' name='pnotify' value=0>No ";
  		  } else {
     	  	$psput .= "<td><input type='radio' name='pnotify' value=1>Yes ";
    	  	$psput .= "<input type='radio' name='pnotify' value=0 checked>No ";
  		  }
  		  $psput .= "<input type='submit' value='Save'></td></tr></form>";
	      $psput .= "<tr><td>Shares A/R:</td><td>" . $pacc . "/" . $prej . "</td>";
	      $psput .= "<td>Reject Ratio:</td>$prat</tr>";
	      if (!defined $prhl) {$prhl = "not set"} else {$prhl = "$prhl%"}
	      $psput .= "<tr><td colspan=2>Reject Ratio alert limit: </td>";
				$psput .= "<form name='pnotifyl' method='POST'>";
				$psput .= "<td>$prhl </td><td><input type='text' size='3' placeholder='3' name='pnotifyl'>";
				$psput .= "<input type='hidden' name='paurl' value='$pname'>";
				$psput .= "<input type='submit' value='Change'></form></td></tr>";

	      $psput .= "<tr><td>Priority:</td><td>" . $ppri . "</td>";
	      $psput .= "<td>Quota:</td><td>" . $ppri . "</td></tr>";
	      $psput .= "<tr><td>Getworks:</td><td>" . $psgw . "</td>";
	      $psput .= "<td>Works:</td><td>" . $psw . "</td></tr>";
	      $psput .= "<tr><td>Discarded:</td><td>" . $psd . "</td>";
	      $psput .= "<td>Stale:</td><td>" . $pss . "</td></tr>";
	      $psput .= "<tr><td>Get Failures:</td><td>" . $psgf . "</td>";
	      $psput .= "<td>Rem Fails:</td><td>" . $psrf . "</td></tr>";
	      $pgimg = "<br><img src='/IFMI/graphs/pool$i.png'>";
	    } else {
	      my $purl = "?";
	      $purl .= "pool=$i";
	      $psum .= '<TR><TD class="bigger"><A href="' . $purl . '">' . $i . '</TD>';
	      $psum .= "<td>" . $pname . "</td>";
#	      $psum .= "<td>" . $poola . "</td>";
	      if (length($pusr) > 20) {
	        $pusr = substr($pusr, 0, 6) . " ... " . substr($pusr, -6, 6) if (index($pusr, '.') < 0);
	      }
	      $psum .= "<td>" . $pusr . "</td>" if ($avers > 1.16);
	      $psum .= $pstatus;
	      $psum .= "<td>" . $pprofile . "</td>" if (defined $pprofile && $pprofile ne "");
	      $psum .= "<td>" . $pacc . " / " . $prej . "</td>";
	      $psum .= $prat;
	      $psum .= "<td>" . $pimg . "</td>";
			  if ($mstrategy eq "Load Balance") {
	      	$psum .= "<td> " . $pquo . " </td>";
	      	$psum .= "<td><form name='pquota' action='status.pl' method='POST'>";
	      	$psum .= "<input type='text' size='3' name='qval' required>";
	      	$psum .= "<input type='hidden' name='qpool' value='$i'>";
	      	$psum .= "<input type='submit' value='Set'></form></td>";
	      }
	      if ($mstrategy eq "Failover") {
	      	if ((defined $spri) && ($spri == 1)) {
			     	$psum .= "<td bgcolor='yellow'>" . $ppri . "</td>";
			    } else {
			     	$psum .= "<td>" . $ppri . "</td>";
			    }
	     	}
      	$psum .= "</tr>";
      }
	  }
	  my $profmenu;
	  if (@profiles) {
	  	$profmenu .= "<select name='setprof'>";
		  for (my $a=0;$a<@profiles;$a++) {
		  	my $profname = ${$profiles[$a]}{'name'};
		  	$profmenu .= "<option value=$profname>$profname</option>";
		  }
		  $profmenu .= "</select>";
	  }
	  $psum .= "<tr><form name='padd' action='status.pl' method='POST'>";
	  $psum .= "<td colspan='8'><input type='text' size='45' placeholder='MiningURL:portnumber' name='npoolurl' required>";
	  $psum .= " <input type='text' placeholder='username.worker' name='npooluser' required>";
	  $psum .= " <input type='text' size='15' placeholder='worker password' name='npoolpw'>";
	  $psum .= " $profmenu" if (@profiles);
	  $psum .= " <input type='submit' value='Add'>";
	  $psum .= "</td></form>";
	  if ($mstrategy eq "Failover") {
		  $psum .= "<TD class='header' colspan=2><form name='padd' method='POST'>";
			$psum .= "<select name='rpri'>";
			for (my $i=0;$i<@pools+1;$i++) {
				if (@pools>$i) {
					my $pname = ${$pools[$i]}{'url'};
	  	  	$psum .= "<option value=$pname>pool $i</option>";
	  	  } else {
	  	  	$psum .= "<option value='z'>off</option>";
	  	  }
  	  }
			$psum .= "</select><br><small>Super Pri</small> <input type='submit' value='Set'>";
		  $psum .= "</form></td>";
	  }
	  if ($mstrategy eq "Load Balance") {
		  $psum .= "<TD class='header' colspan=2>Failover-Only:<br>$mfonly</td>";
	  }
		$psum .= "</tr>";

	} else {
	  $psum .= "<TR><TD colspan='8'><big>Active Pool Information Unavailable</big></td></tr>";
	}
	$psum .= "</table><br>";
	$p1sum .= $psum;

	if (@profiles) {
			$atable = "<table>";
			$atable .= "<tr><h3 class='section_header' align='left'>ALGORITHMS:</h3></tr>";
			$atable .= "<TR class='header'>";
			$atable .= "<TD class='header'>Algo Profile</TD>";
			$atable .= "<TD class='header'>Default</TD>";
			$atable .= "<TD class='header'>Algorithm</TD>";
			$atable .= "<TD class='header'>Algo Type</TD>";
			$atable .= "<TD class='header'>I</TD>";
			$atable .= "<TD class='header'>TC</TD>";
			$atable .= "<TD class='header'>LG</TD>";
			$atable .= "<TD class='header'>Eng</TD>";
			$atable .= "<TD class='header'>Mem</TD>";
			$atable .= "<TD class='header'>Thr</TD>";
			$atable .= "<TD class='header'>Fan</TD>";
			$atable .= "<TD class='header'>Ptune</TD>";
			$atable .= "<TD class='header'>Wsize</TD>";
			$atable .= "<TD class='header'>Remove</TD>";
			$atable .= "</TR>";
			my $apmenu; my $profimg;
		  for (my $a=0;$a<@profiles;$a++) {
		  	my $profname = ${$profiles[$a]}{'name'};
		  	my $profisdef = ${$profiles[$a]}{'is_default'};
	 			if ($profisdef eq "true") {
					$profimg = "<img src='/IFMI/ok24.png'>";
					$apmenu .= "<option value=$profname selected>$profname</option>"
	 			} else {
					$profimg = "";
					$apmenu .= "<option value=$profname>$profname</option>"
	 			}
		  	my $profalgo = ${$profiles[$a]}{'algo'};
		  	my $profatype = ${$profiles[$a]}{'algo_type'};
		  	my $profi = ${$profiles[$a]}{'intensity'}; $profi = "-" if (!defined $profi);
		  	my $proftc = ${$profiles[$a]}{'thread_con'};$proftc = "-" if (!defined $proftc);
		  	my $proflg = ${$profiles[$a]}{'lookup_gap'}; $proflg = "-" if (!defined $proflg);
		  	my $profeng = ${$profiles[$a]}{'gpu_engine'}; $profeng = "-" if (!defined $profeng);
		  	my $profmem = ${$profiles[$a]}{'gpu_memclock'}; $profmem = "-" if (!defined $profmem);
		  	my $profthr = ${$profiles[$a]}{'gpu_threads'}; $profthr = "-" if (!defined $profthr);
		  	my $proffan = ${$profiles[$a]}{'gpu_fan'}; $proffan = "-" if (!defined $proffan);
		  	my $profptune = ${$profiles[$a]}{'gpu_ptune'}; $profptune = "-" if (!defined $profptune);
		  	my $profwsize = ${$profiles[$a]}{'worksize'}; $profwsize = "-" if (!defined $profwsize);
				$atable .= "<tr><td class ='bigger'>" . $profname . "</td>";
				$atable .= "<td>" . $profimg . "</td>";
				$atable .= "<td>" . $profalgo . "</td>";
				$atable .= "<td>" . $profatype . "</td>";
				$atable .= "<td>" . $profi . "</td>";
				$atable .= "<td>" . $proftc . "</td>";
				$atable .= "<td>" . $proflg . "</td>";
				$atable .= "<td>" . $profeng . "</td>";
				$atable .= "<td>" . $profmem . "</td>";
				$atable .= "<td>" . $profthr . "</td>";
				$atable .= "<td>" . $proffan . "</td>";
				$atable .= "<td>" . $profptune . "</td>";
				$atable .= "<td>" . $profwsize . "</td>";
				$atable .= "<td><form name='apdelete' method='POST'>";
		  	$atable .= "<input type='hidden' name='delap' value='$profname'>";
	    	$atable .= "<input type='submit' value='X'></form></td>";
				$atable .= "</tr>";
		  }
		  $atable .= "<tr><form name='apradd' action='status.pl' method='POST'>";
		  $atable .= "<td colspan='14'>";
#		  $atable .= "<select name='uapname'>";
#		  $atable .= $apmenu;
#			$atable .= "</select>";
		  $atable .= " <input type='text' placeholder='Name' name='uapname' required>";
		  $atable .= " <input type='text' placeholder='Algo' name='uapa' required>";
		  $atable .= " <input type='text' size='2' placeholder='I' name='uapi'>";
		  $atable .= " <input type='text' size='2' placeholder='TC' name='uaptc'>";
		  $atable .= " <input type='text' size='2' placeholder='LG' name='uaplg'>";
		  $atable .= " <input type='text' size='3' placeholder='Eng' name='uapeng'>";
		  $atable .= " <input type='text' size='3' placeholder='Mem' name='uapmem'>";
		  $atable .= " <input type='text' size='2' placeholder='Thr' name='uapthr'>";
		  $atable .= " <input type='text' size='2' placeholder='Fan' name='uapfan'>";
		  $atable .= " <input type='text' size='2' placeholder='Ptune' name='uappt'>";
		  $atable .= " <input type='text' size='2' placeholder='Wsize' name='uapws'>";
		  $atable .= " <input type='submit' value='Add'>";
		  $atable .= "</td></form></tr>";
			$atable .= "</table><br>";
	}

} else {
	if (defined $melapsed) {
	  $p1sum .= "<TR><TD id=perror><p>The required API permissions do not appear to be available.<br>";
  	$p1sum .= "please ensure your miner.conf contains the following line:<br>";
  	$p1sum .= '"api-allow" : "W:127.0.0.1",';
  	$p1sum .= "</p></td></tr>";
  	$p1sum .= "</table><br>";
  }
}

# Overview starts here

print "<div id='overview'>";
print "<table><TR><TD>";
print "<table><TR><TD rowspan=2><div class='logo'><a href='https://github.com/starlilyth/Linux-PoolManager' target=_blank>";
print "</a></div></TD>";
print "<TD class='overviewid'>$miner_name<br><small>@ $iptxt</small></td>";
print "<td align='right'><form method='post' action='status.pl' name='zero'>";
print "<input type='hidden' value='zero' name='zero' /><button type='submit' title='reset stats' class='reset-btn'/></form></td>";
print "<tr><TD class='overviewhash' colspan=2>";
$minerate = "0" if (!defined $minerate);
print $minerate . " Mh/s</TD></tr></table></td>";
$mineacc = "0" if (!defined $mineacc);
print "<TD class='overview'>" . $mineacc . " total accepted shares<br>";
$minerej = "0" if (!defined $minerej);
print $minerej . " total rejected shares<br>";
if ($mineacc > 0)
{
 print sprintf("%.3f%%", $minerej / ($mineacc + $minerej)*100);
} else {
 print "0"
}
print " reject ratio";

print "<TD class='overview'>";
if ($problemgpus > 1){
  if ($problemgpus == 1) {
  	print $problemgpus . " GPU has problems<br>";
  } else {
	print $problemgpus . " of " . @gpus . " GPUs have problems<br>";
  }
} else {
  if ($okgpus == 1) {
	print $okgpus . " GPU is OK<br>";
  } else {
	print $okgpus . " of " . @gpus . " GPUs are OK<br>";
  }
}
$minehe = "0" if (!defined $minehe);
if ($minehe == 1) {
  print $minehe . " HW Error<br>";
} else {
  print $minehe . " HW Errors<br>";
}
$minewu = "0" if (!defined $minewu);
print $minewu . " Work Utility<br>";
print "</td>";

# EXTRA HEADER STATS
print "<TD class='overview'>";
my $uptime = `uptime`;
my $rigup = $1 if ($uptime =~ /up\s+(.*?),\s+\d+\s+users?,/);
my $rigload = $1 if ($uptime =~ /average:\s+(.*?),/);
my $memfree = `cat /proc/meminfo | grep MemFree`;
my $rmem = $1 if ($memfree =~ /^MemFree:\s+(.*?)\s+kB$/);
my $rigmem = sprintf("%.3f", $rmem / 1000000);
print "Uptime: $rigup<br>";
print "CPU Load: $rigload<br>";
print "Mem free: $rigmem GB<br>";
# END EXTRA STATS

print "</TR></table></div>";

print "<div id=content>";

given(my $x) {
	when ($showgpu > -1) {
		print "<div id='showdata'>";
		print "<table><tr colspan=2><td><A HREF=?";
		print "tok=1> << Back to overview</A>";
		print "</td></tr>";
		print "<tr><td class='header'>";
		print "<table><tr><td class='bigger'>GPU $showgpu<br>";
		print sprintf("%d", $gpus[$showgpu]{'hashrate'}) . " Kh/s</td></tr>";
		print "<tr><td>";
		if (@gpumsg) {
			print "<img src='/IFMI/error.png'><p>";
			foreach my $l (@gpumsg) {
				print "$l<br>";
			}
		} else {
			print "<img src='/IFMI/ok.png'><p>";
			print "All parameters OK";
		}
		print "</td></tr></table>";

		print "</td><td><div id='sumdata'><table>$gsput</table></div></td></tr>";
		print "<tr><td colspan=2>$ggimg</td></tr></table>";
		print "</div>";
	}
	when ($showpool > -1) {
        print "<div id='showdata'>";
        print "<table><tr><td colspan=2><A HREF=?";
        print "tok=1> << Back to overview</A>";
        print "</td></tr>";
        print "<tr><td class='header'>";
        print "<table><tr><td class='bigger'>Pool $showpool<br>";
        my $psacc = ${$pools[$showpool]}{'accepted'};
        my $psrej = ${$pools[$showpool]}{'rejected'};
		if ($psacc ne "0") {
 	      print sprintf("%.2f%%", $psrej / ($psacc + $psrej)*100) . "</td></tr><tr><td>";
          print "reject ratio";
		} else {
		  print "0 Shares";
		}
		print "</td></tr><tr><td>";
        if (@poolmsg) {
                print "<p><img src='/IFMI/error.png'><p>";
                foreach my $l (@poolmsg)
                {
                        print "$l<br>";
                }
        } else {
                print "<p><img src='/IFMI/ok.png'><p>";
                print "All OK";
        }
   		print "</td></tr></table>";
		print "</td><td><div id='sumdata'><table>$psput</table></div></td></tr>";
		print "<tr><td colspan=2>$pgimg</td></tr></table>";
		print "</div>";
	}
	when ($showminer > -1) {
        print "<div id='showdata'>";
        print "<table><tr><td colspan=2><A HREF=?";
        print "tok=1> << Back to overview</A>";
        print "</td></tr>";
        print "<tr><td class='header'>";
        print "<table><tr><td class='bigger'>" . $miner_name . "<br>";
		if (($minerate ne "0") && ($minewu ne "0")) {
 	      print sprintf("%.1f%%", ($minewu / $minerate) / 10);
		} else { print "0"; }
		print "</td></tr><tr><td>Efficiency <br>(WU / Hashrate)</td></tr>";
		print "<tr><td>";
        if (@nodemsg) {
                print "<img src='/IFMI/error.png'><p>";
                foreach my $l (@nodemsg)
                {
                        print "$l<br>";
                }
        } else {
                print "<p><img src='/IFMI/ok.png'><p>";
                print "All OK";
        }
        my $release = $conf{display}{pmversion};
   		print "</td></tr></table>";
        print "</td><td><table>$msput</td></tr>";
        print "<tr><td colspan=4><hr></td></tr>";
        print "<tr><td colspan=4>PoolManager v$release New releases are available at ";
        print "<a href=https://github.com/starlilyth/Linux-PoolManager/releases target=_blank>GitHub</a>.<br>";
        print "<b>If you love PoolManager, please consider donating. </b>Thank you!<br> ";
        print "BTC: <a href='bitcoin://1JBovQ1D3P4YdBntbmsu6F1CuZJGw9gnV6'><b>1JBovQ1D3P4YdBntbmsu6F1CuZJGw9gnV6</b></a> <br>LTC: <b>LdMJB36zEfTo7QLZyKDB55z9epgN78hhFb</b><br>";
        print "</table></td></tr></table>";
    	print "</div>";
	}
	default {
	  print "<div class='data'>";

	  if ($UHOH eq "true") {
		print "<table><tr><td class=big><p>Uh Oh! No data could be retreived! Please check your configuration and try again.</p></td></tr></table>";
	  } else {
	    print $mcontrol;
	    print $p1sum;
	    print $atable if (defined $atable);
	    print $g1put if (defined $g1put);

		print "<br></div>";
		print "<div class=graphs>";
		print "<table>";
		print "<tr><h3 class='section_header' align='left'>GRAPHS:</h3></tr>";
	
		print "<tr><td align=left>";
		my $img = "/var/www/IFMI/graphs/msummary.png";
		if (-e $img) {
			print '<img src="/IFMI/graphs/msummary.png"><br>';
			print '<img src="/IFMI/graphs/gsummary.png">';
		} else {
			print "<font style='color: #999999; font-size: 10px;'>Summary graph not available yet. Miner may be starting or cannot start.";
		}
		print "</td></tr></table>";
		print "</div>";
	  }
	}
}

print "</body></html>";

