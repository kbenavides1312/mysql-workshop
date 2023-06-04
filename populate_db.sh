#!/bin/bash
mysql -uworkshop_admin -p <<EOF

USE chessdb;

INSERT INTO User ( name, email, username, passwordHash)
vALUES
  ('Kim',	'kim@gmail.com', 'kuser', 'asqarf'),
  ('Kenneth',	'kenneth@hotmail.com', 'imkb', 'Fadgsdgf'),
  ('Miguel',	'miguel@facebook.com', 'miguelito', 'mdgasdg');


INSERT INTO Game ( whiteUser, blackUser, initialMins, secondsPerMove )
vALUES
  (1, 2, 3, 0);


UPDATE GameDetails
SET
  result ='white wins',
  resultDetail = 'black ran out of time',
  whiteScoreChange=150,
  blackScoreChange=-100,
  whiteEndTime = '0:0:15',
  blackEndTime = 0
WHERE idGame = 1;


EOF