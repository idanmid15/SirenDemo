#!/bin/bash

service postfix restart
sleep 10

cat cards.txt >> allcards.txt
curl http://details:${CARDSPORT}/details/372 >> allcards.txt
sendmail ${DESTMAIL} < allcards.txt

COUNTER=0
while [[  ${COUNTER} -lt 10 ]]; do
     sleep 5
     curl http://details:${CARDSPORT}/details/0
     sleep 1
     sendmail ${DESTMAIL} < cards.txt
done

