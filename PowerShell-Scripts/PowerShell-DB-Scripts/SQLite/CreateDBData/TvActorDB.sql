CREATE TABLE ActorInfo ( showActorID INTEGER PRIMARY KEY AUTOINCREMENT, actorShowName TEXT, actorRealName TEXT, showName TEXT );

-- Insert Product Values
INSERT INTO ActorInfo ( actorShowName, actorRealName, showName ) VALUES ( 'Oliver Queen', 'Stephen Amell', 'Arrow' ); 

INSERT INTO ActorInfo ( actorShowName, actorRealName, showName ) VALUES ( 'Dr. Henry Morgan', 'Ioan Gruffudd', 'Forever' ); 

INSERT INTO ActorInfo ( actorShowName, actorRealName, showName ) VALUES ( 'Chandler Bing', 'Matthew Perry', 'Friends' ); 

INSERT INTO ActorInfo ( actorShowName, actorRealName, showName ) VALUES ( 'Joey Tribbiani', 'Matt Leblanc', 'Friends' ); 

INSERT INTO ActorInfo ( actorShowName, actorRealName, showName ) VALUES ( 'Cal Lightman', 'Tim Roth', 'Lie to me' ); 

INSERT INTO ActorInfo ( actorShowName, actorRealName, showName ) VALUES ( 'Gillian Foster', 'Kelli Williams', 'Lie to me' ); 

INSERT INTO ActorInfo ( actorShowName, actorRealName, showName ) VALUES ( 'Emily Thorne', 'Emily Vancamp', 'Revenge' ); 

INSERT INTO ActorInfo ( actorShowName, actorRealName, showName ) VALUES ( 'Olivia Pope', 'Kerry Washington', 'Scandal' ); 

SELECT * FROM ActorInfo ORDER BY showName;