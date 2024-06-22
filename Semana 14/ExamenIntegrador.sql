--1
--Hacer un procedimiento almacenado llamado SP_Descalificar que reciba un ID de
--fotografía y realice la descalificación de la misma. También debe eliminar todas las
--votaciones registradas a la fotografía en cuestión. Sólo se puede descalificar una
--fotografía si pertenece a un concurso no finalizado.

CREATE PROCEDURE SP_Descalificar
(@IdFotografia bigint)
AS
BEGIN
        declare @fin DATE
        select @fin = (select top 1 c.Fin  from Concursos c inner join Fotografias f on f.IDConcurso = c.ID
        where f.ID = @IdFotografia order by c.Fin desc)
      
        if(@fin>getdate())
        begin
        update Fotografias set Descalificada = 1 where ID = @IdFotografia
        delete from Votaciones where IDFotografia = @IdFotografia
        END
        ELSE
        BEGIN
        RAISERROR('Concurso finalizado',16,1)
        RETURN
        END

END

--2
--Al insertar una fotografía verificar que el usuario creador de la fotografía tenga el
--ranking suficiente para participar en el concurso. También se debe verificar que el
--concurso haya iniciado y no finalizado. Si ocurriese un error, mostrarlo con un
--mensaje aclaratorio. De lo contrario, insertar el registro teniendo en cuenta que la
--fecha de publicación es la fecha y hora del sistema.
GO

CREATE TRIGGER VerificarUsuario
ON Fotografias
AFTER INSERT
AS
BEGIN

    DECLARE @IdFotografia bigint,
    @rankingUsuario decimal (5,2),
    @rankingMinimo decimal (5,2),
    @IdParticipante bigint,
    @fechaInicio date,
    @fechaFin date,
    @idConcurso bigint,
    @titulo varchar(150)

     
    select @IdFotografia = i.ID, @IdParticipante=i.IDParticipante, @rankingMinimo = c.RankingMinimo, @fechaInicio = c.Inicio,@fechaFin=c.Fin , @idConcurso=i.IDConcurso , @titulo = i.Titulo
    from inserted i inner join Fotografias f on f.ID = i.ID
    inner join Votaciones v on v.IDVotante = f.IDParticipante
    inner join Concursos c on c.ID = f.IDConcurso 
    set @rankingUsuario =  isnull((select avg(v.Puntaje) from votaciones v  where v.IDVotante = @IdParticipante),0)

    if(@rankingUsuario>= @rankingMinimo and @fechaInicio <= getdate() and @fechaFin>= getdate())
    BEGIN
    insert Fotografias (IDParticipante,IDConcurso,Titulo,Descalificada,Publicacion) 
    values (@IdParticipante,@idConcurso,@titulo,0,getdate() ) 
    END
    ELSE
    BEGIN

    RAISERROR('ranking insuficiente o concurso a destiempo',16,1)
    return
    END


end
    
--3
--Al insertar una votación, verificar que el usuario que vota no lo haga más de una vez
--para el mismo concurso ni se pueda votar a sí mismo. Tampoco puede votar una
--fotografía descalificada. Si ninguna validación lo impide insertar el registro, de lo
--contrario, informar un mensaje de error.

go
CREATE TRIGGER VerificarUsuario
ON Votaciones
AFTER INSERT
AS
BEGIN
declare 
@idVotante bigint,
@idFotografia bigint,
@idConcurso bigint,
@contador int

    DECLARE @Calificacion BIT
    SET @Calificacion = (SELECT F.Descalificada FROM Fotografias AS F
    WHERE F.ID = @IDFotografia
    )
    DECLARE @IDParticipante BIGINT 
    SET @IDParticipante = (SELECT IDParticipante FROM Fotografias
    WHERE ID = @IDFotografia
    )

select  @idFotografia = i.IDFotografia, @idVotante = i.IDVotante, @idConcurso = f.IDConcurso
from inserted i inner join Fotografias f on f.ID = i.IDFotografia
set @contador = (select count(*) from Votaciones AS V
    INNER JOIN Fotografias AS F ON V.IDFotografia = F.ID
    WHERE @IDVotante = V.IDVotante AND F.IDConcurso = @IDConcurso)

 IF(@Contador > 1)
            BEGIN 
                RAISERROR('No es posible votar más de una vez',16,1)
                ROLLBACK TRANSACTION
            END   
    ELSE IF (@IDVotante = @IDParticipante)
            BEGIN 
                RAISERROR ('No está permitiendo votarse a uno mismo, tramposo',16,1)
                ROLLBACK TRANSACTION
            END    
    ELSE IF (@Calificacion = 1)
            BEGIN 
                RAISERROR('No es posible votar a una fotografía descalificada',16,1)
                ROLLBACK TRANSACTION
            END
    ELSE
        BEGIN
            PRINT ('Votación insertada correctamente')
            COMMIT TRANSACTION
        END





END



--Hacer un listado en el que se obtenga: ID de participante, apellidos y nombres de los
--participantes que hayan registrado al menos dos fotografías descalificadas

select p.ID,p.Apellidos,p.Nombres from Participantes p 
inner join Fotografias f on f.IDParticipante = p.ID
WHERE F.Descalificada = 1
GROUP by p.ID,p.Apellidos,p.Nombres
HAVING COUNT(*)>=2

go
select * from Fotografias


--Agregar las tablas y restricciones que sean necesarias para poder registrar las
--denuncias que un usuario hace a una fotografía. Debe poder registrar cuando realiza
--la denuncia incluyendo fecha y hora. Se debe asegurar que se conozcan los datos del
--usuario que denuncia la fotografía, como el usuario que publicó la fotografía y la
--fotografía denunciada. También debe registrarse obligatoriamente un comentario a
--la denuncia y una categoría de denuncia. Las categorías de denuncia habitualmente
--son: Suplantación de identidad, Contenido inapropiado, Infringimiento de derechos
--de autor, etc. Un usuario solamente puede denunciar una fotografía una vez.
go
CREATE TABLE Denunciantes(
    ID BIGINT PRIMARY KEY IDENTITY(1,1),
    Nombre VARCHAR(25) NOT NULL,
    Apellido VARCHAR(25) NOT NULL
)
CREATE TABLE DescripcionCategorias(
    ID INT PRIMARY KEY IDENTITY(1,1),
    Descripcion VARCHAR(250) NOT NULL
)

CREATE TABLE Denuncias(
    ID BIGINT PRIMARY KEY IDENTITY(1,1),
    IDUsuarioDenunciante BIGINT FOREIGN KEY REFERENCES Denunciantes(ID),
    IDFotografia BIGINT FOREIGN KEY REFERENCES Fotografias(ID),
    IDParticipante BIGINT FOREIGN KEY REFERENCES Participantes(ID),
    Comentario VARCHAR(150) NOT NULL,
    FechaHora DATETIME NOT NULL,
    IDDescripcionCategoria INT FOREIGN KEY REFERENCES DescripcionCategorias(ID)
    CONSTRAINT UQ_SeñaladorConstante UNIQUE(IDUsuarioDenunciante,IDFotografia)
)

