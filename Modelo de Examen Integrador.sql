USE [ModeloExamenIntegrador_20241C]
GO
/****** Object:  Trigger [dbo].[tr_agregar_produccion]    Script Date: 10/6/2024 19:11:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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

select   m.Nombre,p.Nombre,(select count(IDOperario)from Operarios)-(count(distinct o.IDOperario)) as cantidadOperarios from Materiales as m inner join Piezas as p on m.IDMaterial = p.IDMaterial
inner join Produccion as pr on pr.IDPieza = p.IDPieza
inner join Operarios as o on o.IDOperario = pr.IDOperario
group by m.Nombre, p.Nombre

--select * from Produccion
--select count(IDOperario)from Operarios
