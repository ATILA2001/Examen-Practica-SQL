USE [ModeloExamenIntegrador_20241C]
GO
/****** Object:  Trigger [dbo].[tr_agregar_produccion]    Script Date: 10/6/2024 19:11:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--1
ALTER   trigger [dbo].[tr_agregar_produccion] on [dbo].[Produccion]
instead of insert
as
begin
 declare	@experiencia smallint
 declare	@costoUnitario money
 declare	@costoTotal money
 declare @cantidad int


 begin transaction

 select @costoUnitario = p.CostoUnitarioProduccion, @experiencia = year(getdate())- o.AnioAlta,@cantidad = i.Cantidad from inserted i
 inner join Piezas p on p.IDPieza = i.IDPieza
 inner join Operarios o on o.IDOperario = i.IDOperario

 if(@experiencia < 5 and @costoUnitario > 15.00)
 begin
 rollback transaction
 raiserror('experiencia insuficiente',16,0)
 return
 end
 else begin
	select @costoTotal = @costoUnitario * @cantidad 
	insert into Produccion (IDOperario, IDPieza, Fecha, Medida, Cantidad,CostoTotal) 
        select  IDOperario, IDPieza, Fecha, Medida, Cantidad, @costoTotal from inserted
		
  end

  commit transaction
end


--2
select   m.Nombre,p.Nombre,(select count(IDOperario)from Operarios)-(count(distinct o.IDOperario)) as cantidadOperarios from Materiales as m inner join Piezas as p on m.IDMaterial = p.IDMaterial
inner join Produccion as pr on pr.IDPieza = p.IDPieza
inner join Operarios as o on o.IDOperario = pr.IDOperario
group by m.Nombre, p.Nombre

--3
create procedure Punto_3 
(@nombre varchar (50),
@valor decimal (6,2)
) as
begin
if(@valor>1000 or @valor<=-100)begin
raiserror('porcentaje incorrecto',16,1)
return
end
	
	declare @IdMaterial smallint 
	select @IdMaterial = m.IDMaterial from Materiales m where m.Nombre like @nombre
	update Piezas set CostoUnitarioProduccion = (@valor / 100-1) where IDMaterial = @IdMaterial

end


--4
go
create procedure Punto_4(
	@fechaInicio date,
	@fechaFin date
	)
	as begin
	select isnull(sum(CostoTotal),0) from Produccion where Fecha between @fechaInicio and @fechaFin
	end


--5

select m.Nombre,sum(p.CostoTotal) as CostoTotal from Materiales m 
inner join Piezas pie on m.IDMaterial = pie.IDMaterial
inner join Produccion p on pie.IDPieza = p.IDPieza
where p.Medida > pie.MedidaMaxima or p.medida < pie.MedidaMinima
group by m.Nombre
having sum(p.CostoTotal) > 100

