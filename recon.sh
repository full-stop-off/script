#!/bin/bash

# Chaos list of subdomain

#funell

#subdomains
subfinder -d $1 -silent | anew $1-subs.txt

# does it resolves?
cat $1-subs.txt | dnsx -resp -silent | anew $1-alive-subs-ip.txt

# adding resolvers with trickest -same as above 
cat $1-subs.txt | dnsx -resp -silent -r ./resolvers.txt | anew $1-alive-subs-ip.txt 
cat $1-subs.txt | dnsx -ro 

# reverse dns lookup
cat $1-alive-subs-ip.txt | dnsx -ptr -ro -r ./resolvers.txt -silent | anew $1-alive-ptr.txt

# Active Testing 

#dns brute force 
cat $1-subs.txt | sed -e 's/\./\n/g' -e 's/\-/\n/g' -e 's/[0-9]*//g' | sort -u | anew host-wordlist.txt 

#  github.com/codingo/DNSCewl --> permutation of wordlist like prefix 
DNSCewl -tL $1-subs.txt -p host-wordlist.txt > $1-domains-fuzz.txt 
cat $1-domains-fuzz.txt | dnx -resp -r ./resolvers.txt | anew $1-bruted.txt


# Port Scanning 

cat $1-alive-subs-ip.txt | nabbu -p 21,22,23,80,81,300,443,591,593,832,981,1010,1311,2082,2087,2095,2096,2480,3000,3128,3333,3389,4567,4711,4712,4993,5000,5104,5108,5800,6543,7000,7396,7474,8000,8001,8008,8014,8042,8069,8080,8081,8088,8090,8091,8118,8123,8172,8222,8243,8280,8281,8333,8443,8500,8834,8880,8888,8983,9000,9043,9060,9080,9090,9091,9200,9443,9800,9981,12443,16080,18091,18092,20720,28017 -silent | anew $1-alive-ports.txt 


cat $1-alive-ports.txt | nabbu -passive -silent | anew $1-alive-ports-scan.txt 

nabbu $1-alive-subs-ip.txt -pf $1-alive-open-ports.txt -nmap-clie 'nmap -sV' -silent | anew scanned-with-nmap.txt 


# WEB Stuff
cat $1-subs.txt | httpx -silent -title -status-code  -td -server| anew $1-web-alive.txt 

cat $1-alive-subs-ip.txt| awk '{print $1}' | sort -u | httpx -silent -title -status-code -td -server | anew $1-web-alive.txt 


cat $1-web-alive.txt | httpx -screenshot -mc 200 

# Crawlling  -> gospider - katana -  hakrawler 
cat $1-alive-subs-ip.txt | awk '{print $1}' | sort -u | gospider -t10 -q -o crawl | anew $1-crawled.txt 
cat $1-crawled.txt | unfurl format %s://%d%p   | anew paths.txt 
cat $1-crawled.txt | unfurl keypairs    | anew param-value.txt 
cat $1-crawled.txt | unfurl format %s://%d%p | httpx -silent -title -status-code -mc 403,400,500 | anew crawled-interesting.txt

# Onelistforall -> github -> mocro.txt -> FUZZING
# ffuf -c -w onelistforallmicro.txt -w $1-fuzz.txt:host -u host/list -c 200,400,403,500 

# WEB ARCHIVE 
cat $1-web-alive.txt | gau -b raw,webp,ico,exif,hdr,tiff,tif,eot,svg,woff,ttf,png,jpg,gif,jpeg,otf,bmp,pdf,mp4,mp3,mov -subs | anew $1-web-gau.txt 

# SSRF 
cat $1-web-gau.txt | gf ssrf | grep "\=https://" 

# collect javascript
cat $1-web-gau.txt | grep -ira "\.js" | httpx -mc 200 -srd js-goldmine

# fuzzing javascript -> we find paramaters and paths 
python3 xnLinkFinder.py -i js-goldmine
cat parameters.tx | sort -u | grep url 

# trufflehog -> leaked keys  
# trufflehog filesystem js-goldmine
# Next -> go with nuclei -> axiom -> shadowclone  
