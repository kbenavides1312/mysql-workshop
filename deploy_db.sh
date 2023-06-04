#!/bin/bash
mysql -uworkshop_admin -p <<EOS

CREATE DATABASE IF NOT EXISTS chessdb;
USE chessdb

CREATE TABLE IF NOT EXISTS chessdb.User (
  idUser INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(45) NULL,
  email VARCHAR(45) NOT NULL,
  username VARCHAR(45) NOT NULL,
  passwordHash VARCHAR(45) NOT NULL,
  PRIMARY KEY (idUser),
  UNIQUE INDEX username_UNIQUE (username ASC) VISIBLE,
  UNIQUE INDEX email_UNIQUE (email ASC) VISIBLE);


CREATE TABLE IF NOT EXISTS chessdb.Score (
  idScore INT NOT NULL AUTO_INCREMENT,
  idUser INT NOT NULL,
  scoreType ENUM('bullet', 'blitz', 'rapid', 'classic') NULL,
  score INT NULL DEFAULT 1500,
  PRIMARY KEY (idScore),
  INDEX fk_idUser_idx (idUser ASC) VISIBLE,
  CONSTRAINT fk_idUser
    FOREIGN KEY (idUser)
    REFERENCES chessdb.User (idUser)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);

CREATE TABLE IF NOT EXISTS chessdb.Game (
  idGame INT NOT NULL AUTO_INCREMENT,
  whiteUser INT NOT NULL,
  blackUser INT NOT NULL,
  whiteScore INT NULL,
  blackScore INT NULL,
  createdAt DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  initialMins INT NULL,
  secondsPerMove INT NULL,
  PRIMARY KEY (idGame),
  INDEX id_idx (whiteUser ASC) VISIBLE,
  INDEX blackUser_idx (blackUser ASC) VISIBLE,
  CONSTRAINT whiteUser
    FOREIGN KEY (whiteUser)
    REFERENCES chessdb.User (idUser)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT blackUser
    FOREIGN KEY (blackUser)
    REFERENCES chessdb.User (idUser)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);

CREATE TABLE IF NOT EXISTS chessdb.GameDetails (
  idGameDetail INT NOT NULL AUTO_INCREMENT,
  idGame INT NOT NULL,
  gameType ENUM('bullet', 'blitz', 'rapid', 'classic') NULL,
  result ENUM('white wins', 'black wins', 'stale mate', 'draw', 'canceled') NULL,
  resultDetail ENUM('white ran out of time', 'black ran out of time', 'white resigned', 'black resigned', 'checkmate') NULL,
  whiteScoreChange INT NULL DEFAULT 0,
  whiteEndTime TIME NULL,
  blackEndTime TIME NULL,
  blackScoreChange INT NULL DEFAULT 0,
  PRIMARY KEY (idGameDetail),
  UNIQUE INDEX idGame_UNIQUE (idGame ASC) VISIBLE,
  CONSTRAINT gd_idGame
    FOREIGN KEY (idGame)
    REFERENCES chessdb.Game (idGame)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);

CREATE TABLE IF NOT EXISTS chessdb.Move (
  idMove INT NOT NULL AUTO_INCREMENT,
  idGame INT NOT NULL,
  turnNumber INT NOT NULL,
  userId INT NOT NULL,
  piece ENUM('k', 'q', 'b', 'n', 'r', 'p') NOT NULL,
  fromCellRow INT NOT NULL,
  fromCellColumn INT NOT NULL,
  toCellRow INT NOT NULL,
  toCellColumn INT NOT NULL,
  PRIMARY KEY (idMove),
  INDEX idGame_idx (idGame ASC) VISIBLE,
  CONSTRAINT m_idGame
    FOREIGN KEY (idGame)
    REFERENCES chessdb.Game (idGame)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);


DELIMITER EOF
CREATE TRIGGER addScore
BEFORE  INSERT ON Game
FOR EACH ROW
BEGIN
  SET @scoreType = CASE
      WHEN NEW.initialMins < 3 THEN 'bullet'
      WHEN NEW.initialMins <= 5 THEN 'blitz'
      WHEN NEW.initialMins <= 10 THEN 'rapid'
      ELSE 'classic'
  END;
  SET NEW.whiteScore = (SELECT score FROM Score s WHERE s.idUser = NEW.whiteUser and s.scoreType=@scoreType);
  SET NEW.blackScore = (SELECT score FROM Score s WHERE s.idUser = NEW.blackUser and s.scoreType=@scoreType);
END;
EOF

DELIMITER EOF
CREATE TRIGGER updateScore
AFTER  UPDATE ON GameDetails
FOR EACH ROW
BEGIN
  IF NEW.whiteScoreChange IS NOT NULL THEN
    SET @whiteUserId = (SELECT whiteUser FROM Game g WHERE g.idGame = OLD.idGame);
    SET @blackUserId = (SELECT blackUser FROM Game g WHERE g.idGame = OLD.idGame);
    UPDATE Score
    SET score = score + NEW.whiteScoreChange
    WHERE idUser = @whiteUserId and scoreType = OLD.gameType;
    UPDATE Score
    SET score = score + NEW.blackScoreChange
    WHERE idUser = @blackUserId and scoreType = OLD.gameType;
  END IF;
END;
EOF

DELIMITER EOF
CREATE TRIGGER addDefaultScores
AFTER  INSERT ON User
FOR EACH ROW
BEGIN
  INSERT INTO Score (idUser, scoreType)
  VALUES
    (NEW.idUser, 'bullet'),
    (NEW.idUser, 'blitz'),
    (NEW.idUser, 'rapid'),
    (NEW.idUser, 'classic');
END;
EOF

DELIMITER EOF
CREATE TRIGGER createGameDetails
AFTER  INSERT ON Game
FOR EACH ROW
BEGIN
  SET @gameType = CASE
      WHEN NEW.initialMins < 3 THEN 'bullet'
      WHEN NEW.initialMins <= 5 THEN 'blitz'
      WHEN NEW.initialMins <= 10 THEN 'rapid'
      ELSE 'classic'
  END;
  INSERT INTO GameDetails (idGame, gameType)
  VALUES
    (NEW.idGame, @gameType);
END;
EOF

EOS