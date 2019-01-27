#! /usr/bin/perl -w
use strict;
use File::Basename;
my $filename;

if ( $#ARGV < 0 ) {
   print "Usage: ".basename($0)."   FILENAME \n";
   exit(1);
}

# Get the first argument
$filename = $ARGV[0];
#print "$filename \n";
open FILE,$filename or die "can't open '$filename':$!";
my $filecontent =join '\n',<FILE>;

#print "$filecontent \n";
#split the string to every create table sql
my @createtablelist =split /\);[\s]*;/,$filecontent;
#open NEWFILE,">new_".$filename or die "can't open new file for write!";
my $i=0;
foreach(@createtablelist){
     #print "abc",$_,"\n";
     #print $i++,"----",$_;
     s/(CREATE[\s]+MULTISET[\s]+TABLE[\s]+[\w]+\.[\w]+).*$/$1/img;
     s/(CREATE[\s]+SET[\s]+TABLE[\s]+[\w]+\.[\w]+).*$/$1/img;
     s/ MULTISET / /ig;
     s/CREATE[\s]+SET[\s]+TABLE/CREATE TABLE/ig;
     s/,NO FALLBACK ,//ig;
     s/NO BEFORE JOURNAL,//ig;
     s/NO AFTER JOURNAL,//ig;
     s/,*CHECKSUM = DEFAULT,*//ig;
     s/,*DEFAULT MERGEBLOCKRATIO,*//ig;
     s/CHARACTER SET LATIN NOT CASESPECIFIC/ /ig;
     s/CHARACTER SET LATIN CASESPECIFIC/ /ig;
     s/FORMAT 'YYYY-MM-DD HH:MI:SS'/ /ig;
     s/FORMAT 'YYYY-MM-DD'/ /ig;
     s/FORMAT 'YYYYMMDD HH:MI:SS'/ /ig;
     s/FORMAT 'YYYYMMDD'/ /ig;
     s/UNIQUE PRIMARY INDEX /with(appendonly=true,orientation=row, compresstype=zlib,compresslevel=5)\nDISTRIBUTED BY /ig;
     s/PRIMARY INDEX /with(appendonly=true,orientation=row, compresstype=zlib,compresslevel=5)\nDISTRIBUTED BY /ig;
     s/( COMPRESS '')/ /ig;
     s/( COMPRESS \(.*\)\))/\)/ig;
     s/( COMPRESS \(.*\))/ /ig;
     s/( COMPRESS \([\d\D]+?\))//ig;
     s/( COMPRESS '[\d\D]+?')/ /ig;
     s/( COMPRESS [\d\.]+ )//ig;
     s/TITLE _UNICODE '[\d\w]+'XC//ig;
      s/NO RANGE OR UNKNOWN//ig;
     s/ CASESPECIFIC/ /ig;
     s /CREATE VOLATILE/CREATE TEMP/ig;
     s /CREATE GLOBAL/CREATE TEMP/ig;
     s /ON COMMIT[\s]+.+;/;/ig;
     #s /ON COMMIT[\s]+.*;$/;/ig;
     s /,[\s]*NO LOG//ig;
     s /(DATE '3000-12-31' AND DATE '3000-12-31' [\d\D]+?\))/\)/ig;
     #print ;
     #get the table name
     my $schemaname;
     my $tablename;
     my $commentstr="";
     #print "def",$_,"\n";
     if(/CREATE[\s]+TEMP[\s]+TABLE[\s]+[\w]+\.([\w]+)/||/CREATE[\s]+TABLE[\s]+([\w]+)\.([\w]+)/||/CREATE[\s]+TEMP[\s]+TABLE ([\w]+)/||/CREATE[\s]+TABLE[\s]+([\w]+)/){
          $schemaname =$1;
          $tablename =$2;
          my $drop_sql="drop table if exists ".$schemaname.".".$tablename.";";
          my @lines =split /\\n/,$_;
          my $curline;
          print "$drop_sql\n";
          foreach $curline (@lines){
               if($curline =~ /([\w_]+?) [\d\D]+? TITLE '([\d\D]+?)'/){
                  $commentstr=$commentstr."COMMENT ON COLUMN ".$schemaname.".".$tablename.".$1 IS '$2';\n";
                  $_=$curline;
                  s/ TITLE '([\d\D]+?)'/ /g;
                  $curline=$_;
               }
               #recreate the partiton part
               #print $curline;
               if($curline =~ /PARTITION BY RANGE_N\(([\d\w_]+)\s+BETWEEN\s+DATE\s+'([\d-]+)'\s+AND\s+DATE\s+'([\d-]+)'\s+EACH\s+INTERVAL\s+'(\d+)'\s+DAY\s+,/){
                    #print "col:$1 from:$2 to:$3 interval:$4";
                    $curline= "PARTITION BY RANGE($1) (START ('$2'::date) END ('$3'::date) EVERY ('$4 day'::interval),DEFAULT PARTITION extra \n";
               }
               elsif($curline =~ /PARTITION BY RANGE_N\(([\d\w_]+)\s+BETWEEN\s+DATE\s+'([\d-]+)'\s+AND\s+DATE\s+'([\d-]+)'\s+EACH\s+INTERVAL\s+'(\d+)'\s+MONTH\s+,/){
                    $curline= "PARTITION BY RANGE($1) (START ('$2'::date) END ('$3'::date) EVERY ('$4 month'::interval),DEFAULT PARTITION extra \n";
                    #print $curline
               }
               #print NEWFILE $curline;
               if ($curline !~/^\s*$/){
               print  $curline;
                  }
           }
          print "\n";
          print $commentstr
          #print NEWFILE ");\n";
          #print NEWFILE $commentstr;
     }

  #last;
}
#print $filecontent;
#close(NEWFILE);
close (FILE);
