create TRIGGER [dbo].[trigger_Alarme] ON [dbo].[Alarme]
AFTER  UPDATE, INSERT
AS
SET NOCOUNT ON
	if SUSER_NAME() <> 'db_user_fabricio'
		begin
			declare @dtNow as datetime = dbo.GetDateCustom()

			Update Interacao
				Set
					Interacao.Realizado = inserted.Realizado,
					Interacao.DtInteracao = inserted.Data,
					Interacao.DtConclusao = case when inserted.Status = 'FI' then inserted.DataUltimoStatus else Interacao.DtConclusao end
				From
					Interacao with (nolock) 
						inner join
					inserted on inserted.Id = Interacao.IdAlarme and inserted.IdSuperEntidade = Interacao.IdSuperEntidade


			update 
				Atendimento 
					set 
						-- deve ser considerado a data do ultimo status já que é a mesma que deverá ser utilizada nos casos de comparação do último alarme ativo
						Atendimento.idAlarmeUltimo =		(Select top 1 Alarme.Id from Alarme where Alarme.IdSuperEntidade = inserted.IdSuperEntidade order by Alarme.DataUltimoStatus desc),
						-- deve ser considerado a data a qual o alarme será executado, para que possa ser considerado a ultima data que o atendimento possuia um próximo passo
						Atendimento.idAlarmeProximoAtivo =	(Select top 1 Alarme.Id from Alarme where Alarme.IdSuperEntidade = inserted.IdSuperEntidade and Alarme.Status = 'IN' order by Alarme.Data asc),
						-- deve ser considerado a data a qual o alarme será executado, para que possa ser considerado a ultima data que o atendimento possuia um próximo passo
						Atendimento.IdAlarmeUltimoAtivo =	(Select top 1 Alarme.Id from Alarme where Alarme.IdSuperEntidade = inserted.IdSuperEntidade and Alarme.Status = 'IN' order by Alarme.Data desc)
				From
					Atendimento with (nolock)
						inner join
					inserted on inserted.IdSuperEntidade = Atendimento.Id


			-- Atualiza a data a ser considerada como última interação do usuário
			-- Essa rotina é rodada em: 
			-- [trigger_Alarme_finalizacao_alarme]
			-- [trigger_interacao_update_atendimento] 
			-- [trigger_atendimento_statusregistro] 
			update 
				Atendimento 
					set InteracaoUsuarioUltimaDt = [dbo].[GetAtendimentoInteracaoUltimaDtUtilConsiderar](inserted.IdSuperEntidade)

				From
					Atendimento with (nolock)
						inner join
					inserted on inserted.IdSuperEntidade = Atendimento.Id

			update
				Alarme set Alarme.DtAtualizacaoAuto = @dtnow
			from
				Alarme
					inner join 
				INSERTED on inserted.Id = Alarme.Id


			-- Atualiza a superentidade para que o tabelão seja atualizado
			-- se faz necessário já que a trigger que altera quando alterado o atendimento nessa trigger
			-- não é disparada em cascata
			update
				SuperEntidade 
					set SuperEntidade.DtAtualizacaoAuto = @dtNow
				from
					SuperEntidade with (nolock)
						inner join
					inserted on inserted.IdSuperEntidade = SuperEntidade.Id
				where
					SuperEntidade.DtAtualizacaoAuto <> @dtNow

	end;

CREATE TRIGGER [dbo].[trigger_atendimento] ON [dbo].[Atendimento]
AFTER  UPDATE, INSERT as
	begin 

		if SUSER_NAME() <> 'db_user_fabricio'
			begin


				declare @idPrimeiroAtendimento int = 0
				declare @dtnow datetime = dbo.getDateCustom()


				-- Seleciona todos os atendimentos da transação independente de qualquer coisa
				-- só desconsidera se o registro em questão será deletado
				Select 
					TabAux.id, TabAux.RegistroStatus into #TempGeral
				from
					(
						Select
							INSERTED.Id, INSERTED.RegistroStatus
						From 
							INSERTED
						where 
							INSERTED.RegistroStatus is null 

							union

						Select
							DELETED.Id, DELETED.RegistroStatus
						From 
							DELETED
						where 
							DELETED.RegistroStatus is null 
					) TabAux


				set @idPrimeiroAtendimento = (select top 1 TabAux1.Id from #TempGeral TabAux1)

				if @idPrimeiroAtendimento is not null
					begin
						-- Atualiza a data a ser considerada como última interação do usuário
						-- Essa rotina é rodada em: 
						-- [trigger_Alarme_finalizacao_alarme]
						-- [trigger_interacao_update_atendimento] 
						-- [trigger_atendimento_statusregistro] 
						update 
							Atendimento 
								set InteracaoUsuarioUltimaDt = [dbo].[GetAtendimentoInteracaoUltimaDtUtilConsiderar](TabAux.Id)

							From
								Atendimento with (nolock)
									inner join
								#TempGeral TabAux on TabAux.Id = Atendimento.Id
							where 
								--InteracaoUsuarioUltimaDt <> [dbo].[GetAtendimentoInteracaoUltimaDtUtilConsiderar](TabAux.Id)
								--	and
								-- se faz necessário para evitar processos desnecessário ja que será excluído
								TabAux.RegistroStatus is null


						-- Faz em todos que estão sendo atualizados
						update
							SuperEntidade set SuperEntidade.DtAtualizacaoAuto = @dtnow
						from
							SuperEntidade
								inner join 
							#TempGeral TabAux on TabAux.Id = SuperEntidade.Id
						where 
							-- se faz necessário para evitar processos desnecessário ja que será excluído
							TabAux.RegistroStatus is null

					end

			end

	end;

CREATE TRIGGER [dbo].[trigger_canal] ON [dbo].[Canal]
after UPDATE, INSERT
AS
SET NOCOUNT ON;

declare @dtnow datetime = dbo.getDateCustom()
declare @dtnowTime time = CONVERT(TIME(0),@dtnow)
declare @dtnowTime2 datetime =  cast(cast(@dtnow as date) as datetime)
declare @dtnowTime3 datetime = cast(cast(DATEADD(DAY, 1, @dtnow) as date) as datetime)

-- Caso TimeExpurgoChat sofra alteração
IF (UPDATE (TimeExpurgoChat))
	begin
		-- Caso a hora do expurgo que está sendo inserida ou atualizada for nulo 
		-- irá setar DtProximoExpurgoChat como nulo
		-- SETARÁ tb a data de expurgo como nula para que caso altere de canal chat para outro
		if (select min(inserted.TimeExpurgoChat) from inserted) is null or (select min(inserted.Tipo) from inserted) <> 'CHAT'
			begin
				update canal set DtProximoExpurgoChat = null, TimeExpurgoChat = NULL
				from
					Canal
						inner join
					inserted on Canal.id = inserted.Id
			end
		else
			begin
				update
					Canal
				set
					Canal.DtProximoExpurgoChat =	(
														-- caso a hora do expurgo seja maior que a data atual
														-- irá concatenar a data atual mais a hora do expurgo
														-- caso seja menor, significa que só irá executar no dia seguinte na hora do expurgo
														CASE  
															WHEN 
																inserted.TimeExpurgoChat > @dtnowTime
															THEN
																@dtnowTime2 + cast(inserted.TimeExpurgoChat as datetime)
															ELSE 
																@dtnowTime3 + cast(inserted.TimeExpurgoChat as datetime)
														END 
													)
	
				from
					inserted
						left outer join
					Canal on Canal.Id = inserted.Id
				where
					inserted.TimeExpurgoChat is not null
			end
	end

	IF (UPDATE(status))
		begin
			-- Seleciona todos os canais que por ventura esteja sendo inativado
			Select
				inserted.id into #TempTableMudancaDeStatus
			From
				inserted
					inner join
				deleted on inserted.Id = deleted.Id and inserted.Status <> deleted.Status and inserted.Status = 'IN'

			-- Deleta o canal desativado de todas as campanhas que faz parte
			delete CampanhaCanal
			from
				CampanhaCanal
					inner join
				#TempTableMudancaDeStatus TabAux on TabAux.Id = CampanhaCanal.IdCanal

		END;

CREATE TRIGGER [dbo].[trigger_contasistema_disable]
ON [dbo].[ContaSistema]
AFTER UPDATE, DELETE   
	AS  
		BEGIN
		    SET NOCOUNT ON;

			IF UPDATE (Status) 
				BEGIN
					if exists (
								Select
									INSERTED.Id
								From 
									inserted
										inner join
									DELETED on DELETED.Id = inserted.Id
								where 
									deleted.Status = 'AT'
										and
									inserted.Status <> 'AT' 
										and
									exists
										(
											Select 
												TelefoniaDID.Id
											From
												TelefoniaDID
													inner join
												TransportadoraContaSistema on TransportadoraContaSistema.IdTransportadora = TelefoniaDID.IdTelefoniaTransportadora

											where
												TransportadoraContaSistema.IdContaSistema = INSERTED.Id
													and
												TelefoniaDID.Status = 'AT'
										)
								)
								BEGIN
								   ROLLBACK TRANSACTION;
								   --RAISERROR ('You must disable Trigger "safety" to remove synonyms!', 10, 1)  
								   RAISERROR (15600,-1,-1, 'Não é possível desativar a instância com números DID ativo. Favor verificar.');  

								   RETURN;
								END
							ELSE if exists (
												Select
													INSERTED.Id
												From 
													inserted
														inner join
													DELETED on DELETED.Id = inserted.Id
												where 
													deleted.Status = 'AT'
														and
													inserted.Status <> 'AT'
												)
												BEGIN
													UPDATE ContaSistema set ContaSistema.DtCancelamento = dbo.GetDateCustom() 
													FROM
														inserted
															inner join
														DELETED on DELETED.Id = inserted.Id
															inner join
														ContaSistema on ContaSistema.Id = DELETED.Id
												END
				END				
		END;

CREATE TRIGGER [dbo].[trigger_GrupoSuperior_statusregistro] ON [dbo].[GrupoSuperior]
AFTER  UPDATE, INSERT
AS
SET NOCOUNT ON

update GrupoSuperior set StatusRegistroBach = 'DE' 
from
	GrupoSuperior
		inner join 
	INSERTED on inserted.id = GrupoSuperior.id;

CREATE TRIGGER [dbo].[trigger_interacao_update_atendimento] ON [dbo].[Interacao]
AFTER  UPDATE, INSERT
AS
SET NOCOUNT ON

begin
	DECLARE @login_name VARCHAR(256) = (SELECT login_name FROM sys.dm_exec_sessions WHERE session_id = @@SPID)

	if @login_name <> 'db_user_fabricio'
		begin
    

			declare @dtNow as datetime = dbo.GetDateCustom()

			update 
				Atendimento 
					set 
						Atendimento.idInteracaoUsuarioUltima =	(
																	CASE  
																		WHEN inserted.InteracaoAtorPartida = 'USUARIO' 
																			THEN (Select top 1 Interacao.Id from Interacao with (nolock) where IdSuperEntidade = inserted.IdSuperEntidade and Interacao.InteracaoAtorPartida = inserted.InteracaoAtorPartida order by Interacao.DtInclusao desc)
																			ELSE Atendimento.idInteracaoUsuarioUltima
																	END 
																),
						Atendimento.idInteracaoProspectUltima =	(
																	CASE  
																		WHEN inserted.InteracaoAtorPartida = 'PROSPECT' 
																			THEN (Select top 1 Interacao.Id from Interacao with (nolock) where IdSuperEntidade = inserted.IdSuperEntidade and Interacao.InteracaoAtorPartida = inserted.InteracaoAtorPartida order by Interacao.DtInclusao desc)
																			ELSE Atendimento.IdInteracaoProspectUltima
																	END 
																),
						Atendimento.idInteracaoAutoUltima =		(
																	CASE  
																		WHEN inserted.InteracaoAtorPartida = 'AUTO' 
																			THEN (Select top 1 Interacao.Id from Interacao with (nolock) where IdSuperEntidade = inserted.IdSuperEntidade and Interacao.InteracaoAtorPartida = inserted.InteracaoAtorPartida order by Interacao.DtInclusao desc)
																			ELSE Atendimento.IdInteracaoAutoUltima
																	END 
																),
						Atendimento.idInteracaoNegociacaoVendaUltima =	(
																	CASE  
																		WHEN InteracaoTipo.Tipo = 'NEGOCIACAOVENDA'
																			THEN (Select top 1 Interacao.Id from Interacao with (nolock) inner join InteracaoTipo with (nolock) on InteracaoTipo.id = inserted.IdInteracaoTipo  where IdSuperEntidade = inserted.IdSuperEntidade and InteracaoTipo.Tipo = 'NEGOCIACAOVENDA' order by Interacao.DtInteracao desc, Interacao.Id desc)
																			ELSE Atendimento.idInteracaoNegociacaoVendaUltima
																	END 
																)
				From
					Atendimento with (nolock)
						inner join
					inserted on inserted.IdSuperEntidade = Atendimento.Id
						inner join 
					InteracaoTipo with (nolock) on InteracaoTipo.id = inserted.IdInteracaoTipo


			-- Atualiza a data a ser considerada como última interação do usuário
			-- Essa rotina é rodada em: 
			-- [trigger_Alarme_finalizacao_alarme]
			-- [trigger_interacao_update_atendimento] 
			-- [trigger_atendimento_statusregistro] 
			update 
				Atendimento 
					set InteracaoUsuarioUltimaDt = [dbo].[GetAtendimentoInteracaoUltimaDtUtilConsiderar](inserted.IdSuperEntidade)

				From
					Atendimento with (nolock)
						inner join
					inserted on inserted.IdSuperEntidade = Atendimento.Id

			-- Atualiza a superentidade para que o tabelão seja atualizado
			-- se faz necessário já que a trigger que altera quando alterado o atendimento nessa trigger
			-- não é disparada em cascata
			update
				SuperEntidade set SuperEntidade.DtAtualizacaoAuto = @dtNow
			from
				inserted
					inner join
				SuperEntidade with (nolock) on SuperEntidade.Id = inserted.IdSuperEntidade
			where
				SuperEntidade.DtAtualizacaoAuto <> @dtNow
		end


end;

CREATE TRIGGER [dbo].[trigger_pessoaProspect_statusregistro] ON [dbo].[PessoaProspect]
AFTER  UPDATE, INSERT
AS
SET NOCOUNT ON

		if SUSER_NAME() <> 'db_user_fabricio'
			begin
				declare @dtnow datetime = dbo.getDateCustom()


				update SuperEntidade set SuperEntidade.DtAtualizacaoAuto  = @dtnow
					from
						SuperEntidade
							inner join 
						INSERTED on inserted.Id = SuperEntidade.Id

				update SuperEntidade set SuperEntidade.DtAtualizacaoAuto  = @dtnow
					from
						Atendimento
							inner join 
						SuperEntidade on SuperEntidade.Id = Atendimento.Id
							inner join 
						INSERTED on inserted.Id = Atendimento.idPessoaProspect
			end;

-- atualiza os idAtendimento dos que ainda não foram setados
-- provavelmente os registros de entrada do chat ou faleconosco ja que nesse momento ainda n existe atendimento
-- se faz necessário para ficar mais fácil de localizar os logs
CREATE TRIGGER [dbo].[trigger_PessoaProspectIntegracaoLog_idAtendimento] ON [dbo].[PessoaProspectIntegracaoLog]
AFTER  INSERT
AS
SET NOCOUNT ON

update PessoaProspectIntegracaoLog set PessoaProspectIntegracaoLog.IdAtendimento = inserted.IdAtendimento 
from
	PessoaProspectIntegracaoLog with (nolock)
		inner join 
	INSERTED on inserted.KeyMaxVendas = PessoaProspectIntegracaoLog.KeyMaxVendas
where 
	inserted.IdAtendimento is not null 

update PessoaProspectIntegracaoLog set PessoaProspectIntegracaoLog.IdAtendimento = inserted.IdAtendimento 
from
	PessoaProspectIntegracaoLog with (nolock)
		inner join 
	INSERTED on inserted.KeyMaxVendasCookie = PessoaProspectIntegracaoLog.KeyMaxVendasCookie
where 
	inserted.IdAtendimento is not null;
