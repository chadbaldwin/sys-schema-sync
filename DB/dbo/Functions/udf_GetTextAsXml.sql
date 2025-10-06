CREATE OR ALTER FUNCTION dbo.udf_GetTextAsXml
(
	@text nvarchar(MAX)
)
RETURNS xml
WITH INLINE = ON
AS
BEGIN
	RETURN (
		SELECT [processing-instruction(q)] = TRANSLATE(
												REPLACE('--'
													+ CHAR(13)+CHAR(10)
													+ @text
													+ CHAR(13)+CHAR(10)
													+ '--'
													, '?>', '??'
												) COLLATE Latin1_General_BIN2
												, CONCAT('',0x01020304050607080B0C0E0F101112131415161718191A1B1C1D1E1F00)
												, '?????????????????????????????'
											)
		FOR XML PATH(''), TYPE
	)
END;
GO