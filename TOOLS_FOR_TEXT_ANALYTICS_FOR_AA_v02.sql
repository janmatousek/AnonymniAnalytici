/*STAVEBNI KAMENY*/

/*database*/
create database TEXT_DB_DEMO;

/*switch db*/
use[TEXT_DB_DEMO] ;

/*ČEštna žije?*/
SELECT * FROM sys.fulltext_languages order by lcid



/*fulltext table for primary index*/

drop table ZEMAN;

CREATE TABLE [dbo].[ZEMAN](
	
	Datum[nvarchar](20), Nazev[nvarchar](100),castka[nvarchar](20) , [text][nvarchar](max),	
	--[id_pk] [int] NOT NULL,
  --CONSTRAINT id_pk2 PRIMARY KEY  (Datum, Nazev, castka, text) 
	) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
	;  

select * from ZEMAN;

/*LOAD DATA - CHANGE PATH*/
BULK INSERT 
   ZEMAN
      FROM 'd:\New Folder\milosuvucet_v02.txt' --XXX zmýnit cestu k souboru 
      WITH 
    ( 
   BATCHSIZE = 50
   ,  CODEPAGE = 'ACP' -- kˇdovßnÝ ŔeÜtiny 
    ,  DATAFILETYPE =  'char' 
    ,  FIELDTERMINATOR = '\t' --oddýlovaŔ sloupc¨ 
   ,  FIRSTROW = 19 -- import zaŔÝnß na °ßdku 13
   ,  MAXERRORS = 100 --...toleruje do 100000 chyb 
   ,  ROWS_PER_BATCH = 50
    ,  ROWTERMINATOR = '\n'
	) 
	;


/*Potřebujeme index jak koza drbání. Seřadíme náhodu a dáme ji do sloupce*/
drop table ZEMAN2;

/*PK is for primary key NESMIME TAM DOVOLIT NULL PROTO NOT NULL */
CREATE TABLE [dbo].[ZEMAN2](
	[Datum] [nvarchar](20) NULL,
	[Nazev] [nvarchar](100) NULL,
	[castka] [nvarchar](20) NULL,
	[text] [nvarchar](max) NULL,
	[pk] [int] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

insert into ZEMAN2
select Z.*
, 
cast (
rank() over (order by newid()) 
as int )
as pk 
from ZEMAN as Z;


/*index MUSI BYT UNIKATNI NOT NULLABLE - jiz vyreseno a kratky INTEGER - jiz vyreseno */
 create unique index   ix on ZEMAN2 (pk) ;


/*CZ tezaurus, neexistuje, pokud ho msft nenapsal, takže tohle hazi chybu ale NEVA*/
EXEC sys.sp_fulltext_load_thesaurus_file 1029;


/*KOUZLO CISLO 1 FULLTEXTOVE INDEXOVANA TABULE*/
CREATE FULLTEXT CATALOG [ZEMANUV_KATALOG];
GO
CREATE FULLTEXT INDEX ON ZEMAN2
 ( 
  text
     Language 1029
  ) 
  KEY INDEX ix
      ON ZEMAN2; 
GO

	  ; 



/*FULLTEXT SEARCH, bez skloňování*/
SELECT text
FROM ZEMAN2
WHERE FREETEXT (text, 'kunda')



/*LEmatizer - rozložení na slova - jen tupý příklad */
SELECT * FROM sys.dm_fts_parser (' "Zeman je Pán" ' , 1029, 0, 0)

/*WOrd Frequency, opět bez skloňování*/
select
display_term as word, count (*) as FREQUENCY --, IdentityID, id_pk
into tmp_terms_full /*uložíme si frekvence slov*/
from ZEMAN2
cross apply sys.dm_fts_parser('"' + [text] + '"',0,0,0)
where text is not null
group by display_term
order by count (*) desc 

/*bacha mašina umí sloňovat */
SELECT *
FROM sys.dm_fts_parser
('FORMSOF(INFLECTIONAL,'+ 'mít' + ')', 1029, 0, 0);





/*PROCHAZIME KURZOREM TOP 100 SLOV A KAZDE VYSKLONUJEME*/

declare @text as varchar (4000)
DECLARE contact_cursor CURSOR FOR
SELECT top 100 word FROM tmp_terms_full where word is not null and word not like '' order by FREQUENCY desc 
OPEN contact_cursor;
FETCH NEXT FROM contact_cursor into @text;
-- Perform the first fetch.
-- Check @@FETCH_STATUS to see if there are any more rows to fetch.
WHILE @@FETCH_STATUS = 0
BEGIN
FETCH NEXT FROM contact_cursor into @text ;
   -- This is executed as long as the previous fetch succeeds.
SELECT newid(), ph.*, @text
FROM sys.dm_fts_parser 
('FORMSOF(INFLECTIONAL,'+ @text + ')', 1029, 0, 0) as ph
--where expansion_type = 0;
END
CLOSE contact_cursor;
DEALLOCATE contact_cursor;



DECLARE @TableName NVARCHAR(200) = 'ZEMAN2'
DECLARE @ColumnName NVARCHAR(200) = 'text'













/*VYTVARIME SLOVNIK, ZATIM BEZ KONTROLY SLOV */
DROP TABLE DICTIONARY ;
CREATE TABLE  DICTIONARY (keyword varchar (255), group_id int, phrase_id int, occurence int, special_term varchar (255), display_term varchar(255), expansion_type int, source_term varchar (255) );
declare @text as varchar (4000)
DECLARE contact_cursor CURSOR FOR
select   word from tmp_terms_full order by FREQUENCY desc 
OPEN contact_cursor;
FETCH  FROM contact_cursor into @text;

-- Perform the first fetch.
;

-- Check @@FETCH_STATUS to see if there are any more rows to fetch.
WHILE @@FETCH_STATUS = 0
BEGIN
FETCH NEXT FROM contact_cursor into @text;

   -- This is executed as long as the previous fetch succeeds.

insert into DICTIONARY
SELECT *
FROM sys.dm_fts_parser
('FORMSOF(INFLECTIONAL,'+ @text + ')', 1029, 0, 0);
	
END
CLOSE contact_cursor;
DEALLOCATE contact_cursor;
GO

select * from DICTIONARY order by source_term desc , display_term ;

/*UKOLY NA CVICENI 
-Povstimnet si co dela sloupec expansion_type a jaky je asi jeho vyznam 
0. Udelejte tabulku document_id, term
0a. Udelete word frequency se sklonovanim /*stemming/s pomoci slovniku 
1. OVERTE SLOVA POMOCI FREEWARE SLOVNIKU NAPRIKLAD SLOVNIKU PRO  PSPAD
	a. prvni pady 
	b. vysklonovana slova pomoci lepsich slovniku jako syn2010lemma
2. PRIPOJTE FREE NEBO  PLACENY SLOVNIK EMOCI NAPRIKLAD SUBLEX 1.0

*/