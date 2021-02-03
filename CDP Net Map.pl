#!/usr/bin/perl -w
# I originally found this script on the internet and updated it for the latest version of Net::SNMP. 
# I unfortunately do not remember where I found this, I am only posting it here because I have made 
# some very minor changes to it.
use strict;
use Net::SNMP;
my($error,$session,$seed_oid,$oid_root,$community,$hostname,$seed_ip);
my(%done);
my(@todo);
$done{"0.0.0.0"}=1; 



#We need a startin point, get an IP from command line
die "usage: $0 seedip" unless ( @ARGV == 1 ); 
$seed_ip = $ARGV[0];
die "usage: $0 seedip" unless ($seed_ip =~ m{\d+\.\d+\.\d+\.\d+});


Prompt for SNMP community string
print "community: ";
chomp($community = <STDIN>);
print "Community = ".$community;
@todo=($seed_ip); #List of possible targets
$oid_root = "1.3.6.1.4.1.9.9.23.1.2.1.1";
$seed_oid = ("$oid_root".".3");

while(@todo){ #Grab a target and go to work
    
    $hostname= shift(@todo);
    unless(exists $done{$hostname}){  #Make sure we haven't done this one yet

        print "\n\nCDP Neighbor Details for $hostname\n";
        print "--------------------------------------------------------------------------------------------\n";
        print "Neighbor IP                 Name                   Interface                   Type        |\n";
        print "--------------------------------------------------------------------------------------------\n";


        $done{$hostname}=1; #Remember that we checked this IP 
        #Open SNMP session
        ($session,$error) = Net::SNMP->session(Hostname => $hostname, Community => $community);
		print "No session!\n" unless($session);
        return unless($session);
    
        get_oids($seed_oid); #Get the SNMP info for this target

        $session->close;

    }
}

    #----------------------------------------------------------
    #This sub finds out how many neighbors the target has 
    #and determines what oids we need to use to get the info that
    #we want, then calls other subs to get that info
    #----------------------------------------------------------
    sub get_oids{
        my($starting_oid , $new_oid , $unique_oid , $result , $crap);
        my($ip , $name , $port , $type);
		my $counter;
        $starting_oid = $_[0];
        $new_oid = $starting_oid ;
        $counter = 0;
        
        while(Net::SNMP::oid_base_match($starting_oid,$new_oid)){
			$counter++;
            $result = $session->get_next_request(($new_oid));
			print "No request result!\n" unless (defined $result);
            return  unless (defined $result);
            ($new_oid , $crap) = %$result;
            if (Net::SNMP::oid_base_match($starting_oid,$new_oid)){
            $unique_oid = $new_oid;
            $unique_oid =~ s/$starting_oid//g;
            $ip = (Convert_IP(Get_SNMP_Info("$oid_root".".4"."$unique_oid")));
            $name = (Get_SNMP_Info("$oid_root".".6"."$unique_oid"));
            $port = (Get_SNMP_Info("$oid_root".".7"."$unique_oid"));
            $type = (Get_SNMP_Info("$oid_root".".8"."$unique_oid"));
            @todo=(@todo,$ip);
            write;
            get_oids($new_oid);
            
            }
        }
#Format the report
format STDOUT =  
@<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< 
$ip,				$name,					$port,					    $type
.
    }

        sub Convert_IP{ #This sub converts a hex IP to standard xxx.xxx.xxx.xxx format 
            my($ip , $result , $crap);
            my($hex1 , $hex2 , $hex3 , $hex4);
            my($oct1 , $oct2 , $oct3 , $oct4);
            my($hex_ip) = $_[0] ;
        
            if (substr($hex_ip,0,1) eq ""){ 
                $ip = "0.0.0.0";
            }
            else{
                $hex_ip =~ s/0x//g;
                $hex1 = (substr $hex_ip,0,2);
                $hex2 = (substr $hex_ip,2,2);
                $hex3 = (substr $hex_ip,4,2);
                $hex4 = (substr $hex_ip,6,2);
        
                $oct1 = hex($hex1);
                $oct2 = hex($hex2);
                $oct3 = hex($hex3);
                $oct4 = hex($hex4);
                $ip = ("$oct1\.$oct2\.$oct3\.$oct4");
            }
            return $ip;
        }

        sub Get_SNMP_Info{ #This sub gets the value of an oid
        
            my($crap , $value , $result);
            my($oid) = $_[0];
            $result = $session->get_request("$oid");
            return unless (defined $result);
            ($crap , $value) = %$result;
            return $value;

        }





