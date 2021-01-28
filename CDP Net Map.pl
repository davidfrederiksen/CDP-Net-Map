#!/usr/bin/perl -w
# cdppoll.pl
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


#Prompt for SNMP community string
print "community: ";
chomp($community = <STDIN>);

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
        $starting_oid = $_[0];
        $new_oid = $starting_oid ;
        
        
        while(Net::SNMP::oid_base_match($starting_oid,$new_oid)){
            $result = $session->get_next_request(($new_oid));
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
#format STDOUT =  @<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<< 
#				$ip,				$name,								$port,					$type. 
#				.
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
            #return unless (defined $result);
            ($crap , $value) = %$result;
            return $value;

        }



=head1 Name
    cdppoll.pl

=head1 Summary
 This script takes one IP as an argument, uses SNMP to find
 that IPs CDP Neighbors, and then uses the IPs it gathers
 to find more CDP neighbors.
 
 Your network infrastructure should get mapped pretty
 quickly assuming that all of your devices are:
     1. Cisco routers or switches
     2. Using the same Read-Only Community string
     3. Permitting SNMP traffic to the box you are 
        running the script from.
       
 The network that this was tested on is composed of:
     2600 and 3600 series routers
     2900, 3500, 6500 series Catalyst switches
     2500 series terminal access device

=head1 Updated

 5-17-2001
  Cleaned things up a lot more. Started using POD, and modified the in
+line comments
  to improve readability.
  Got rid of get_target sub (it really shouldn't have been a sub at al
+l)
  Code now works with strict

 5-16-2001 
  Cleaned up the code a little bit. Made the get_ip get_name get_port 
+and get_type 
  subs a single sub Get_SNMP_Info 
  Moved all of the IP conversion code into its own sub Convert_IP
  The code should be several steps closer to being strict compliant.
 

 5-16-2001 
  Corrected a problem with how the script reacted if it has a neighbor
+ with no IPaddress. 
  It will now display 0.0.0.0 when it sees a null value for IP.

 5-16-2001 
  Initial working code posted
 
  
=head1 TODO  
  1. Add in better error handling and error messages
  2. Find a better way to check for IPs, currently
     999.9999.9999 would be seen as a valid target 
  3. Work on making the subroutines more blackbox-ish
  
=head1 Thanks
 Hopefully this will be usefull to someone other than myself
 Thanks to all the monks that answered my basic questions
 instead of telling me to RTFM
=cut
