-- dbo.AtendimentoBookMarkView source

CREATE VIEW [dbo].[AtendimentoBookMarkView]
AS
	Select 
		BookmarkSuperEntidade.IdSuperEntidade,
		BookmarkSuperEntidade.IdUsuarioContaSistema,
		STRING_AGG(Bookmark.IdGuid, ',') as BookmarkIdGuids
	From
		BookmarkSuperEntidade with (nolock)
			inner join
		Bookmark with (nolock) on BookmarkSuperEntidade.IdBookmark = Bookmark.Id and BookmarkSuperEntidade.IdUsuarioContaSistema = Bookmark.IdUsuarioContaSistema
	group by
		BookmarkSuperEntidade.IdSuperEntidade,
		BookmarkSuperEntidade.IdUsuarioContaSistema;


-- dbo.AtendimentoResumoView source

CREATE VIEW [dbo].[AtendimentoResumoView]
AS
	Select 
		TabAux.*,
		(case when CampanhaConfiguracao.id is not null then DATEADD(day, CampanhaConfiguracao.ValorInt, TabAux.InteracaoUltimaDtUtilConsiderar)  else null end) as AtendimentoDtExpiracao,
		CampanhaConfiguracao.ValorInt as AtendimentoConfiguracaoQtdDiasExpiracao

	from
	(
		Select 
			SuperEntidadeAtendimento.idContaSistema as ContasistemaId,
			ContaSistema.Guid as ContasistemaIdGuid,
		
			Atendimento.Id as Atendimentoid,
			Atendimento.versao as AtendimentoVersao,
			SuperEntidadeAtendimento.StrGuid as AtendimentoIdGuid,
			Atendimento.DtInclusao as AtendimentoDtInclusao,
			Atendimento.DtInicioAtendimento as AtendimentoDtInicio,
			Atendimento.DtConclusaoAtendimento as AtendimentoDtConclusao,
			Atendimento.StatusAtendimento as AtendimentoStatus,
			Atendimento.negociacaoStatus  as AtendimentoNegociacaoStatus,
			Atendimento.RegistroStatus as AtendimentoRegistroStatus,
			Atendimento.TipoDirecionamento as AtendimentoTipoDirecionamento,
			Atendimento.ValorNegocio as AtendimentoValorNegocio,
			Atendimento.ComissaoNegocio as AtendimentoComissaoNegocio,
	
			Produto.Id as ProdutoId,
			Produto.GUID as ProdutoIdGuid,
			Produto.Nome as ProdutoNome,
			Produto.UF as ProdutoUF,
		
			--isnull((Select Marco.Valor from dbo.GetMarcoProduto(Produto.Id, SuperEntidadeAtendimento.DtInclusao) Marco), ' - ') as ProdutoMarco,
			convert(varchar(1), null) as ProdutoMarco,
				
			Canal.Id as CanalId,
			Canal.GUID as CanalIdGuid,
			Canal.Nome as CanalNome,
			Canal.Meio as CanalMeio,
		
			Atendimento.idMidia as MidiaId,
			Midia.GUID as MidiaIdGuid,
			Midia.Nome as MidiaNome,
			MidiaTipo.Valor as MidiaTipoValor,

			IntegradoraExterna.Id as IntegradoraExternaId,
			IntegradoraExterna.StrKey as IntegradoraExternaIdGuid,
			IntegradoraExterna.ExtensaoLogo as IntegradoraExternaExtensaoLogo,
			IntegradoraExterna.Nome as IntegradoraExternaNome,
		
			Atendimento.IdPeca as PecaId,
			Peca.GUID as PecaIdGuid,
			Peca.Nome as PecaNome,
		
			CampanhaMarketing.Id as CampanhaMarketingId,
			CampanhaMarketing.Nome as CampanhaMarketingNome,
		
			GrupoPecaMarketing.Id as GrupoPecaMarketingId,
			GrupoPecaMarketing.Nome as GrupoPecaMarketingNome,
		
			Atendimento.IdGrupo as GrupoId,
			Grupo.IdGuid as GrupoIdGuid,
			Grupo.Nome as GrupoNome,
			GrupoAux.GrupoHierarquia,
			GrupoAux.GrupoHierarquiaTipo,
			Tag.Valor AS GrupoTag,
		
			Atendimento.idClassificacao as ClassificacaoId,
			Classificacao.IdGuid as ClassificacaoIdGuid,
			Classificacao.Valor as ClassificacaoValor,
			Classificacao.Valor2 as ClassificacaoValor2,
			Classificacao.Ordem as ClassificacaoOrdem,
		
			Atendimento.IdCampanha as CampanhaId,
			Campanha.GUID as CampanhaIdGuid,
			Campanha.Nome as CampanhaNome,
		
			Atendimento.idUsuarioContaSistemaCriacao as CriouAtendimentoUsuarioContaSistemaId,
			PessoaCriacao.Nome as CriouAtendimentoPessoaNome,
		
			UsuarioContaSistema.GUID as UsuarioContaSistemaIdGuid,
			Usuario.GuidUsuarioCorrex as UsuarioGuidUsuarioCorrex,
			Atendimento.IdUsuarioContaSistemaAtendimento as UsuarioContaSistemaId,
			UsuarioContaSistema.Status as UsuarioContaSistemaStatus,
		
			UsuarioContaSistema.IdPessoa as PessoaId,
			Pessoa.Nome as PessoaNome,
			Pessoa.Apelido as PessoaApelido,
			Pessoa.Email as PessoaEmail,
		
			Isnull(dbo.GetProdutoSubList(Atendimento.Id), 'Nenhum') as ProdutoSubList,
			cast(dbo.GetEmailsProspectList(Atendimento.IdPessoaProspect) as varchar(800)) as PessoaProspectEmailList,
			cast(dbo.GetTelefonesProspectList(Atendimento.IdPessoaProspect) as varchar(800)) as PessoaProspectTelefoneList,
			cast(ISNULL(dbo.GetTagsProspectList(Atendimento.IdPessoaProspect),'Nenhum') as varchar(800)) as PessoaProspectTagList,

			Atendimento.IdPessoaProspect as PessoaProspectId,
			SuperEntidadePessoaProspect.StrGuid as PessoaProspectIdGuid,
			PessoaProspect.DtInclusao as PessoaProspectDtInclusao,
			PessoaProspect.Nome as PessoaProspectNome,
			(Select Max(PessoaProspectDocumento.Doc) from PessoaProspectDocumento  WITH (NOLOCK) where PessoaProspectDocumento.IdPessoaProspect = PessoaProspect.Id and PessoaProspectDocumento.TipoDoc = 'CPF') AS PessoaProspectCPF, 
			PessoaProspect.Sexo as PessoaProspectSexo,
			PessoaProspect.DtNascimento as PessoaProspectDtNascimento,
			PessoaProfissao.Nome as PessoaProspectProfissao,

			Prospeccao.Id as ProspeccaoId,
			Prospeccao.Nome as ProspeccaoNome,
		
			CASE WHEN (atendimento.negociacaoStatus = 'GANHO') THEN 1 ELSE 0 END as AtendimentoConvercaoVenda,
		
			Atendimento.IdMotivacaoNaoConversaoVenda as AtendimentoIdMotivacaoNaoConversaoVenda,
			Motivacao.Descricao as AtendimentoMotivacaoNaoConversaoVenda,

			InteracaoUltima.Id as InteracaoPrimeiraId,
			Atendimento.DtInicioAtendimento as InteracaoPrimeiraDtFull,

			-- ultima interação negociação venda
			Atendimento.idInteracaoNegociacaoVendaUltima  as InteracaoNegociacaoVendaUltimaId,
			InteracaoNegociacaoVendaUltima.DtInclusao as InteracaoNegociacaoVendaUltimaDtFull,

			-- Ultima interação do usuário
			InteracaoUltima.Id as InteracaoUltimaId,
			InteracaoUltima.DtInclusao as InteracaoUltimaDtFull,
			InteracaoUltimaTipo.Valor as InteracaoUltimaTipoValor,
			InteracaoUltimaTipo.ValorAbreviado as InteracaoUltimaTipoValorAbreviado,
			
			-- Ultimo alarme ativo do atendimento
			AlarmeUltimoAtivo.id as AlarmeUltimoAtivoId,
			AlarmeUltimoAtivo.Data as AlarmeUltimoAtivoData,
			AlarmeUltimoAtivoInteracaoTipo.Valor as AlarmeUltimoAtivoInteracaoTipoValor,

			-- Proximo alarme ativo do atendimento
			AlarmeProximoAtivo.id as AlarmeProximoAtivoId,
			AlarmeProximoAtivo.Data as AlarmeProximoAtivoData,
			AlarmeProximoAtivoInteracaoTipo.Valor as AlarmeProximoAtivoInteracaoTipoValor,

			(
				SELECT 
					-- Se faz necessário adicionar sempre 1 a data máxima retornada
					MAX(AtendimentoDtExpirar)
				FROM 
					(
						VALUES (Atendimento.DtInicioAtendimento), (InteracaoUltima.DtInclusao), (AlarmeUltimo.DataUltimoStatus), (AlarmeUltimoAtivo.Data), (SuperEntidadeAtendimento.DtInclusao)
					) AS UpdateDate(AtendimentoDtExpirar)
			) AS InteracaoUltimaDtUtilConsiderar,

			PessoaProspectEndereco1.PessoaEnderecoUF as PessoaEnderecoUF1,
			PessoaProspectEndereco1.PessoaEnderecoCidade as PessoaEnderecoCidade1,
			PessoaProspectEndereco1.PessoaEnderecoBairro as PessoaEnderecoBairro1,
			PessoaProspectEndereco1.PessoaEnderecoLogradouro as PessoaEnderecoLogradouro1,
			PessoaProspectEndereco1.PessoaEnderecoComplemento as PessoaEnderecoComplemento1,
			PessoaProspectEndereco1.PessoaEnderecoNumero as PessoaEnderecoNumero1,
			PessoaProspectEndereco1.PessoaEnderecoCEP as PessoaEnderecoCEP1,
			PessoaProspectEndereco1.PessoaEnderecoLatitude as PessoaEnderecoLatitude1,
			PessoaProspectEndereco1.PessoaEnderecoLongitude as PessoaEnderecoLongitude1,
			PessoaProspectEndereco1.PessoaEnderecoTipo as PessoaEnderecoTipo1,

			PessoaProspectEndereco2.PessoaEnderecoUF as PessoaEnderecoUF2,
			PessoaProspectEndereco2.PessoaEnderecoCidade as PessoaEnderecoCidade2,
			PessoaProspectEndereco2.PessoaEnderecoBairro as PessoaEnderecoBairro2,
			PessoaProspectEndereco2.PessoaEnderecoLogradouro as PessoaEnderecoLogradouro2,
			PessoaProspectEndereco2.PessoaEnderecoComplemento as PessoaEnderecoComplemento2,
			PessoaProspectEndereco2.PessoaEnderecoNumero as PessoaEnderecoNumero2,
			PessoaProspectEndereco2.PessoaEnderecoCEP as PessoaEnderecoCEP2,
			PessoaProspectEndereco2.PessoaEnderecoLatitude as PessoaEnderecoLatitude2,
			PessoaProspectEndereco2.PessoaEnderecoLongitude as PessoaEnderecoLongitude2,
			PessoaProspectEndereco2.PessoaEnderecoTipo as PessoaEnderecoTipo2,

			SuperEntidadeAtendimento.DtAtualizacaoAuto as DtAtualizacaoAuto

		From
			Atendimento WITH (NOLOCK)
				inner join
			SuperEntidade SuperEntidadeAtendimento WITH (NOLOCK) on  SuperEntidadeAtendimento.Id = Atendimento.id
				inner join
			PessoaProspect WITH (NOLOCK) on Atendimento.IdPessoaProspect = PessoaProspect.Id	
				inner join
			SuperEntidade SuperEntidadePessoaProspect WITH (NOLOCK) on PessoaProspect.id = SuperEntidadePessoaProspect.Id	
				inner join
			ContaSistema  WITH (NOLOCK) on ContaSistema.id = SuperEntidadeAtendimento.idContaSistema
				left outer join
			UsuarioContaSistema WITH (NOLOCK) on Atendimento.IdUsuarioContaSistemaAtendimento = UsuarioContaSistema.Id
				left outer join
			Usuario WITH (NOLOCK) on Usuario.IdPessoa =  UsuarioContaSistema.IdPessoa
				left outer join
			Produto WITH (NOLOCK) on Produto.Id = Atendimento.IdProduto
				left outer join
			Canal WITH (NOLOCK) on Canal.Id = Atendimento.IdCanalAtendimento
				left outer join
			Motivacao WITH (NOLOCK) on Motivacao.Id = Atendimento.IdMotivacaoNaoConversaoVenda
				left outer join
			Midia WITH (NOLOCK) on Midia.Id = Atendimento.idMidia
				left outer join
			MidiaTipo WITH (NOLOCK) on Midia.IdMidiaTipo = MidiaTipo.Id			
				left outer join
			Peca WITH (NOLOCK) on Peca.Id = Atendimento.IdPeca
				left outer join
			IntegradoraExterna WITH (NOLOCK) on Midia.IdIntegradoraExterna = IntegradoraExterna.Id
				left outer join
			CampanhaMarketing WITH (NOLOCK) on CampanhaMarketing.Id = Atendimento.IdCampanhaMarketing
				left outer join
			GrupoPecaMarketing WITH (NOLOCK) on GrupoPecaMarketing.Id = Atendimento.IdGrupoPecaMarketing
				left outer join	
			Grupo WITH (NOLOCK) on Grupo.Id = Atendimento.IdGrupo
				left outer join	
			GrupoAux WITH (NOLOCK) on GrupoAux.Id = Grupo.Id
				left outer join
			Tag  WITH (NOLOCK) on Tag.Id = Grupo.IdTag
				LEFT OUTER JOIN
			Classificacao WITH (NOLOCK) on Classificacao.id = Atendimento.idClassificacao
				left outer join
			Campanha WITH (NOLOCK) on Campanha.Id = Atendimento.IdCampanha
				left outer join
			Pessoa WITH (NOLOCK) on Pessoa.Id = UsuarioContaSistema.IdPessoa
				left outer join
			UsuarioContaSistema UsuarioContaSistemaCriacao WITH (NOLOCK) on Atendimento.idUsuarioContaSistemaCriacao = UsuarioContaSistemaCriacao.Id
				left outer join
			Pessoa PessoaCriacao  WITH (NOLOCK) on UsuarioContaSistemaCriacao.IdPessoa = PessoaCriacao.Id
				left outer join
			Interacao InteracaoUltima  WITH (NOLOCK) on InteracaoUltima.Id = Atendimento.IdInteracaoUsuarioUltima
				left outer join
			InteracaoTipo InteracaoUltimaTipo WITH (NOLOCK)  on InteracaoUltima.IdInteracaoTipo = InteracaoUltimaTipo.Id
				left outer join
			
			Interacao InteracaoNegociacaoVendaUltima WITH (NOLOCK)  on InteracaoNegociacaoVendaUltima.Id = Atendimento.idInteracaoNegociacaoVendaUltima
				left outer join

			-- Ultimo alarme que existiu no atendimento independete de ativo
			Alarme AlarmeUltimo  with (nolock) on AlarmeUltimo.id = Atendimento.IdAlarmeUltimo and Atendimento.StatusAtendimento = 'ATENDIDO'
				left outer join

			-- Ultimo alarme ativo no sistema que ainda não foi encerrado
			Alarme AlarmeUltimoAtivo  with (nolock) on AlarmeUltimoAtivo.Id = Atendimento.IdAlarmeUltimoAtivo and Atendimento.StatusAtendimento = 'ATENDIDO' 
				left outer join
			Interacao AlarmeUltimoAtivoInteracao with (nolock) on AlarmeUltimoAtivoInteracao.idAlarme = AlarmeUltimoAtivo.id
				left outer join
			InteracaoTipo AlarmeUltimoAtivoInteracaoTipo with (nolock) on AlarmeUltimoAtivoInteracaoTipo.Id = AlarmeUltimoAtivoInteracao.IdInteracaoTipo
				left outer join

			-- Proximo alarme ativo no sistema que ainda não foi encerrado
			Alarme AlarmeProximoAtivo  with (nolock) on AlarmeProximoAtivo.Id = Atendimento.IdAlarmeProximoAtivo and Atendimento.StatusAtendimento = 'ATENDIDO'
				left outer join
			Interacao AlarmeProximoAtivoInteracao with (nolock) on AlarmeProximoAtivoInteracao.idAlarme = AlarmeProximoAtivo.id
				left outer join
			InteracaoTipo AlarmeProximoAtivoInteracaoTipo with (nolock) on AlarmeProximoAtivoInteracaoTipo.Id = AlarmeProximoAtivoInteracao.IdInteracaoTipo


				left outer join
			Prospeccao WITH (NOLOCK)  on Prospeccao.id = Atendimento.IdProspeccao
				left outer join
			PessoaProfissao WITH (NOLOCK)  on PessoaProfissao.id = PessoaProspect.IdPessoaProfissao
				left outer join
			(
				Select
					TabAux1.IdPessoaProspect,
					TabAux1.PessoaProspectEnderecoId,
					PessoaProspectEndereco.UF as PessoaEnderecoUF,
					DbLocalidadeCidade.Nome as PessoaEnderecoCidade,
					DbLocalidadeBairro.Nome as PessoaEnderecoBairro,
					PessoaProspectEndereco.Logradouro as PessoaEnderecoLogradouro,
					PessoaProspectEndereco.Complemento as PessoaEnderecoComplemento,
					PessoaProspectEndereco.Numero as PessoaEnderecoNumero,
					PessoaProspectEndereco.CEPNumber as PessoaEnderecoCEP,
					ISNULL(DbLocalidadeCEPLogradouro.latitude, DbLocalidadeCidade.latitude) as PessoaEnderecoLatitude,
					ISNULL(DbLocalidadeCEPLogradouro.longitude, DbLocalidadeCidade.longitude) as PessoaEnderecoLongitude,
					PessoaProspectEndereco.Tipo as PessoaEnderecoTipo
				from 
					(
						Select
							PessoaProspectEndereco.IdPessoaProspect, 
							min(PessoaProspectEndereco.Id) as PessoaProspectEnderecoId
						from 
							PessoaProspectEndereco WITH (NOLOCK) 
						group by 
							PessoaProspectEndereco.IdPessoaProspect
					) TabAux1
						inner join
					PessoaProspectEndereco WITH (NOLOCK) on TabAux1.PessoaProspectEnderecoId = PessoaProspectEndereco.Id
						left outer join
					DbLocalidadeCidade  WITH (NOLOCK) on DbLocalidadeCidade.Id = PessoaProspectEndereco.IdCidade
						left outer join
					DbLocalidadeBairro WITH (NOLOCK) on DbLocalidadeBairro.Id = PessoaProspectEndereco.IdBairro
						left outer join
					DbLocalidadeCEPLogradouro WITH (NOLOCK) on DbLocalidadeCEPLogradouro.CEP = PessoaProspectEndereco.CEPNumber
			) PessoaProspectEndereco1 on PessoaProspectEndereco1.IdPessoaProspect = PessoaProspect.Id
				left outer join
			(
				Select
					TabAux1.IdPessoaProspect,
					TabAux1.PessoaProspectEnderecoId,
					PessoaProspectEndereco.UF as PessoaEnderecoUF,
					DbLocalidadeCidade.Nome as PessoaEnderecoCidade,
					DbLocalidadeBairro.Nome as PessoaEnderecoBairro,
					PessoaProspectEndereco.Logradouro as PessoaEnderecoLogradouro,
					PessoaProspectEndereco.Complemento as PessoaEnderecoComplemento,
					PessoaProspectEndereco.Numero as PessoaEnderecoNumero,
					PessoaProspectEndereco.CEPNumber as PessoaEnderecoCEP,
					ISNULL(DbLocalidadeCEPLogradouro.latitude, DbLocalidadeCidade.latitude) as PessoaEnderecoLatitude,
					ISNULL(DbLocalidadeCEPLogradouro.longitude, DbLocalidadeCidade.longitude) as PessoaEnderecoLongitude,
					PessoaProspectEndereco.Tipo as PessoaEnderecoTipo
				from 
					(
						Select
							PessoaProspectEndereco.IdPessoaProspect, 
							max(PessoaProspectEndereco.Id) as PessoaProspectEnderecoId
						from 
							PessoaProspectEndereco WITH (NOLOCK) 
						group by 
							PessoaProspectEndereco.IdPessoaProspect
					) TabAux1
						inner join
					PessoaProspectEndereco WITH (NOLOCK) on TabAux1.PessoaProspectEnderecoId = PessoaProspectEndereco.Id
						left outer join
					DbLocalidadeCidade  WITH (NOLOCK) on DbLocalidadeCidade.Id = PessoaProspectEndereco.IdCidade
						left outer join
					DbLocalidadeBairro WITH (NOLOCK) on DbLocalidadeBairro.Id = PessoaProspectEndereco.IdBairro
						left outer join
					DbLocalidadeCEPLogradouro WITH (NOLOCK) on DbLocalidadeCEPLogradouro.CEP = PessoaProspectEndereco.CEPNumber
			) PessoaProspectEndereco2 on PessoaProspectEndereco2.IdPessoaProspect = PessoaProspect.Id and PessoaProspectEndereco2.PessoaProspectEnderecoId <> PessoaProspectEndereco1.PessoaProspectEnderecoId
	) TabAux
			left outer join
	CampanhaCanal  WITH (NOLOCK) on CampanhaCanal.IdCampanha = TabAux.CampanhaId and CampanhaCanal.IdCanal = TabAux.CanalId and CampanhaCanal.UsarCanalNoAutoEncerrar = 1
			left outer join
	CampanhaConfiguracao WITH (NOLOCK) ON CampanhaConfiguracao.IdCampanha = CampanhaCanal.IdCampanha and CampanhaConfiguracao.Tipo = 'ENCERRAR_ATENDIMENTO_SEM_FOLLOWUP' and CampanhaConfiguracao.ValorInt > 0 and TabAux.AtendimentoStatus = 'ATENDIDO';


-- dbo.AtendimentoSeguidorView source

CREATE VIEW [dbo].[AtendimentoSeguidorView]
AS
	Select 
		ViewUsuarioContaSistemaDetalhado.UsuarioContaSistemaIdContaSistema as IdContaSistema,
		AtendimentoSeguidor.IdAtendimento,
		AtendimentoSeguidor.DtInclusao,
		AtendimentoSeguidor.IdPessoaProspect,
		AtendimentoSeguidor.IdUsuarioContaSistema,
		ViewUsuarioContaSistemaDetalhado.UsuarioContaSistemaIdGuid,
		ViewUsuarioContaSistemaDetalhado.UsuarioContaSistemaGuidCorrex,
		ViewUsuarioContaSistemaDetalhado.PessoaApelido as UsuarioApelido,
		ViewUsuarioContaSistemaDetalhado.PessoaNome as UsuarioNome,
		ViewUsuarioContaSistemaDetalhado.PessoaEmail as UsuarioEmail

	From
		AtendimentoSeguidor with (nolock)
			inner join
		ViewUsuarioContaSistemaDetalhado  with (nolock) on ViewUsuarioContaSistemaDetalhado.UsuarioContaSistemaId = AtendimentoSeguidor.IdUsuarioContaSistema
	where 
		AtendimentoSeguidor.Status = 'AT';


-- dbo.Bairro source

CREATE view [dbo].[Bairro] as
select
   dbo.DBLocalidadeBairro.Id as IdBairro,
   dbo.DBLocalidadeBairro.IdCidade,
   dbo.DBLocalidadeBairro.NomeOficial as NomeOficialBairro,
   dbo.DBLocalidadeBairro.Nome as NomeBairro,
   dbo.DBLocalidadeBairro.NomeAbreviado as NomeAbreviadoBairro,
   Cidade.UF,
   Cidade.Nome as NomeCidade,
   Cidade.NomeAbreviado as NomeAbreviadoCidade,
   Cidade.Tipo as TipoCidade
from
	dbo.DBLocalidadeBairro  WITH (NOLOCK)
		INNER JOIN
	Cidade  WITH (NOLOCK)  on  dbo.DBLocalidadeBairro.IdCidade = Cidade.Id;


-- dbo.CEPFaixaBairro source

/*==============================================================*/
/* View: CEPFaixaBairro                                         */
/*==============================================================*/
CREATE view [dbo].[CEPFaixaBairro] as
select
   dbo.DBLocalidadeCEPFaixaBairro.IdBairro,
   dbo.DBLocalidadeCEPFaixaBairro.FaixaCEPInicio,
   dbo.DBLocalidadeCEPFaixaBairro.FaixaCEPFim,
   Bairro.IdCidade,
   Bairro.NomeOficialBairro,
   Bairro.NomeBairro,
   Bairro.NomeAbreviadoBairro,
   Bairro.UF,
   Bairro.NomeCidade,
   Bairro.NomeAbreviadoCidade,
   Bairro.TipoCidade
from
   dbo.DBLocalidadeCEPFaixaBairro WITH (NOLOCK) 
		INNER JOIN 
	Bairro WITH (NOLOCK)  on  dbo.DBLocalidadeCEPFaixaBairro.IdBairro = Bairro.IdBairro;


-- dbo.CEPFaixaCidade source

/*==============================================================*/
/* View: CEPFaixaCidade                                         */
/*==============================================================*/
CREATE view [dbo].[CEPFaixaCidade] as
select
   dbo.DBLocalidadeCEPFaixaCidade.IdCidade,
   dbo.DBLocalidadeCEPFaixaCidade.FaixaCEPInicio,
   dbo.DBLocalidadeCEPFaixaCidade.FaixaCEPFim,
   Cidade.UF,
   Cidade.Nome,
   Cidade.NomeAbreviado,
   Cidade.Tipo
from
	dbo.DBLocalidadeCEPFaixaCidade  WITH (NOLOCK) 
		INNER JOIN 
	Cidade  WITH (NOLOCK) on  dbo.DBLocalidadeCEPFaixaCidade.IdCidade = Cidade.Id;


-- dbo.CEPFaixaUF source

/*==============================================================*/
/* View: CEPFaixaUF                                             */
/*==============================================================*/
CREATE view [dbo].[CEPFaixaUF] as
SELECT     UF, FaixaCEPInicio, FaixaCEPFim
FROM         dbo.DBLocalidadeCEPFaixaUF  WITH (NOLOCK);


-- dbo.CEPLogradouro source

/*==============================================================*/
/* View: CEPLogradouro                                          */
/*==============================================================*/
CREATE view [dbo].[CEPLogradouro] as
select
   dbo.DBLocalidadeCEPLogradouro.IdBairro,
   dbo.DBLocalidadeCEPLogradouro.Nome,
   dbo.DBLocalidadeCEPLogradouro.Complemento,
   dbo.DBLocalidadeCEPLogradouro.UtilizaTipo,
   dbo.DBLocalidadeCEPLogradouro.Tipo,
   dbo.DBLocalidadeCEPLogradouro.CEP,
   dbo.DBLocalidadeCEPLogradouro.Abreviacao,
   dbo.DBLocalidadeCEPLogradouro.latitude,
   dbo.DBLocalidadeCEPLogradouro.longitude,
   Bairro.IdCidade,
   Bairro.NomeOficialBairro,
   Bairro.NomeBairro,
   Bairro.NomeAbreviadoBairro,
   Bairro.UF,
   Bairro.NomeCidade,
   Bairro.NomeAbreviadoCidade,
   Bairro.TipoCidade
from
   dbo.DBLocalidadeCEPLogradouro   WITH (NOLOCK) 
		INNER JOIN 
   dbo.Bairro   WITH (NOLOCK) on  dbo.DBLocalidadeCEPLogradouro.IdBairro = Bairro.IdBairro;


-- dbo.Cidade source

/*==============================================================*/
/* View: Cidade                                                 */
/*==============================================================*/
CREATE view [dbo].[Cidade] as
SELECT     Id, UF, Nome, NomeAbreviado, Tipo
FROM         dbo.DBLocalidadeCidade WITH (NOLOCK);


-- dbo.GrupoHierarquiaView source

CREATE VIEW [dbo].[GrupoHierarquiaView]
AS
SELECT
	TabGrupoSuperior.Nome as GrupoSuperiorNome,
	Tag.Valor as GrupoSuperiorTipo,
	GrupoHierarquia.Nivel,
	GrupoHierarquia.IdGrupoInferior,
	GrupoHierarquia.IdGrupoSuperior,
	TabGrupoSuperior.IdContaSistema,
	TabGrupoSuperior.Mostrar
	
FROM
	GrupoHierarquia with (NOLOCK)
		INNER JOIN
	Grupo TabGrupoSuperior with (NOLOCK) on TabGrupoSuperior.Id = GrupoHierarquia.IdGrupoSuperior
		left outer join
	Tag  with (NOLOCK) on Tag.Id = TabGrupoSuperior.IdTag;


-- dbo.UF source

/*==============================================================*/
/* View: UF                                                     */
/*==============================================================*/
CREATE view [dbo].[UF] as
SELECT     Sigla, Nome
FROM         DBLocalidadeUF  WITH (NOLOCK);


-- dbo.ViewInteracao source

CREATE view [dbo].[ViewInteracao] as
Select 
	Interacao.idContaSistema as ContaSistemaId,
	Interacao.IdSuperEntidade as AtendimentoId,
	InteracaoMarketing.Id as InteracaoMarketingId,
	InteracaoMarketing.DtInclusao as InteracaoMarketingDtInclusao,
	Canal.Nome as CanalNome,
	Produto.Nome as ProdutoNome,
	Interacao.Id as InteracaoId,
	Interacao.DtInteracao as InteracaoDtInteracao,
	Interacao.InteracaoAtorPartida,
	InteracaoTipo.Id as InteracaoTipoId,
	InteracaoTipo.Valor as InteracaoTipoValor,
	InteracaoTipo.Tipo as InteracaoTipoTipo,

	Midia.Nome as MidiaNome,
	Peca.Nome as PecaNome,

	IntegradoraExternaAgencia.Nome as IntegradoraExternaAgenciaNome,
	IntegradoraExternaEmpresaIntegradora.Nome as IntegradoraExternaEmpresaIntegradoraNome,
	TabAuxIntegradoraExternaEmpresaIntegradora.PessoaProspectIntegracaoLogId as PessoaProspectIntegracaoLogID

from 
	InteracaoMarketing with (nolock)
		left outer join
	Interacao with (nolock) on Interacao.IdInteracaoMarketing =  InteracaoMarketing.Id
		left outer join
	InteracaoTipo  with (nolock) on InteracaoTipo.Id = Interacao.IdInteracaoTipo
		left outer join
	Canal  with (nolock) on Canal.Id = Interacao.IdCanal
		left outer join
	Produto  with (nolock) on Produto.Id = Interacao.IdProduto
		left outer join
	Midia  with (nolock) on Midia.Id = InteracaoMarketing.IdMidia
		left outer join
	Peca  with (nolock) on Peca.Id = InteracaoMarketing.IdPeca
		left outer join
	IntegradoraExterna  IntegradoraExternaAgencia  with (nolock) on  IntegradoraExternaAgencia.Id = InteracaoMarketing.IdIntegradoraExternaAgencia
		left outer join
	IntegradoraExterna IntegradoraExternaEmpresaIntegradora  with (nolock) on  IntegradoraExternaEmpresaIntegradora.Id = InteracaoMarketing.IdIntegradoraExterna
		left outer join
	(
		Select PessoaProspectIntegracaoLog.idInteracao, Max(PessoaProspectIntegracaoLog.Id) as PessoaProspectIntegracaoLogId
		from
			PessoaProspectIntegracaoLog with (nolock)
		group by
			PessoaProspectIntegracaoLog.idInteracao 
	) TabAuxIntegradoraExternaEmpresaIntegradora on TabAuxIntegradoraExternaEmpresaIntegradora.idInteracao = Interacao.Id;


-- dbo.ViewUsuarioContaSistemaByCampanha source

/*==============================================================*/
/* View: [ViewUsuarioContaSistemaByCampanha] */
/*==============================================================*/
CREATE view [dbo].[ViewUsuarioContaSistemaByCampanha] as
select
	distinct 
		Campanha.Id as CampanhaId,
		UsuarioContaSistema.id as UsuarioContaSistemaId,
		UsuarioContaSistema.FilaCanalOnLine as UsuarioContaSistemaFilaCanalOnLine, 
		UsuarioContaSistema.FilaCanalOffLine as UsuarioContaSistemaFilaCanalOffLine, 
		UsuarioContaSistema.FilaCanalTelefone as UsuarioContaSistemaFilaCanalTelefone, 
		UsuarioContaSistema.FilaCanalWhatsApp as UsuarioContaSistemaFilaCanalWhatsApp, 
		UsuarioContaSistema.DtUltimaRequisicao as UsuarioContaSistemaDtUltimaRequisicao,
		Pessoa.Nome as PessoaNome,
		Pessoa.Apelido as PessoaApelido,
		Pessoa.Email as PessoaEmail,
		Grupo.Nome as GrupoNome,
		Grupo.Id as GrupoId,
		GrupoAux.GrupoHierarquia as GrupoHierarquia,
		CampanhaGrupo.Id as CampanhaGrupoId,
		Campanha.IdContaSistema as ContaSistemaId

from 
	Campanha WITH (NOLOCK)
		inner join
	CampanhaGrupo WITH (NOLOCK)on CampanhaGrupo.IdCampanha = Campanha.Id
		inner join
	Grupo WITH (NOLOCK) on Grupo.Id = CampanhaGrupo.IdGrupo
		inner join
	(
		Select 
			UsuarioContaSistemaGrupo.idGrupo,
			UsuarioContaSistemaGrupo.idUsuarioContaSistema
		from 
			UsuarioContaSistemaGrupo  WITH (NOLOCK)
		where 
			UsuarioContaSistemaGrupo.DtFim is null

			union

		Select 
			UsuarioContaSistemaGrupoAdm.idGrupo,
			UsuarioContaSistemaGrupoAdm.idUsuarioContaSistema
		from 
			UsuarioContaSistemaGrupoAdm  WITH (NOLOCK)
		where 
			UsuarioContaSistemaGrupoAdm.DtFim is null
	) TabAuxUsuarioContaSistema on TabAuxUsuarioContaSistema.IdGrupo = Grupo.Id
		inner join
	UsuarioContaSistema WITH (NOLOCK) on TabAuxUsuarioContaSistema.IdUsuarioContaSistema = UsuarioContaSistema.Id
		inner join
	Pessoa WITH (NOLOCK) on Pessoa.Id = UsuarioContaSistema.IdPessoa
		left outer join
	GrupoAux with (nolock) on GrupoAux.id = Grupo.Id

Where
	UsuarioContaSistema.Status = 'AT' and
	CampanhaGrupo.Status = 'AT' and
	Grupo.Status = 'AT';


-- dbo.ViewUsuarioContaSistemaDetalhado source

CREATE view [dbo].[ViewUsuarioContaSistemaDetalhado] as
select
	UsuarioContaSistema.GUID as UsuarioContaSistemaIdGuid,
	UsuarioContaSistema.Id as UsuarioContaSistemaId,
	UsuarioContaSistema.Status as UsuarioContaSistemaStatus,
	UsuarioContaSistema.DtExpiracao as UsuarioContaSistemaDtExpiracao,
	UsuarioContaSistema.DtUltimaRequisicao as UsuarioContaSistemaDtUltimaRequisicao,
	UsuarioContaSistema.IdContaSistema as UsuarioContaSistemaIdContaSistema,
	UsuarioContaSistema.QtdAcesso as UsuarioContaSistemaQtdAcessos,
	UsuarioContaSistema.FilaCanalOffLine as UsuarioContaSistemaFilaCanalOffLine,
	UsuarioContaSistema.FilaCanalOnLine as UsuarioContaSistemaFilaCanalOnLine,
	UsuarioContaSistema.FilaCanalTelefone as UsuarioContaSistemaFilaCanalTelefone,
	UsuarioContaSistema.FilaCanalWhatsApp as UsuarioContaSistemaFilaCanalWhatsApp,

	Pessoa.Nome as PessoaNome,
	Pessoa.Apelido as PessoaApelido,
	Pessoa.Email as PessoaEmail, 
	dbo.GetPessoaTelefoneList(Pessoa.Id) as pessoaTelefones, 
	
	PessoaFisica.CPF as PessoaFisicaCPF,
	PessoaFisica.Creci as PessoaFisicaCreci,
	PessoaFisica.DtNascimento as PessoaFisicaDtNascimento,
	PessoaFisica.Sexo as PessoaFisicaSexo,

	Usuario.GuidUsuarioCorrex as UsuarioContaSistemaGuidCorrex,

	PerfilUsuario.Guid as PerfilUsuarioIdGuid,

	ContaSistema.Nome as ContaSistemaNome,
	ContaSistema.Guid as ContaSistemaIdGuid,
	ContaSistema.GuidCorrex as ContaSistemaCorrexIdGuid
	
from
	UsuarioContaSistema with (nolock)
		inner join
	ContaSistema with (nolock) on UsuarioContaSistema.IdContaSistema = ContaSistema.Id
		inner join
	Pessoa with (nolock) on Pessoa.Id = UsuarioContaSistema.IdPessoa
		inner join
	Usuario with (nolock) on Usuario.IdPessoa = UsuarioContaSistema.IdPessoa
		left outer join
	PessoaFisica with (nolock) on Pessoa.Id = PessoaFisica.IdPessoa
		left outer join
	PerfilUsuario  with (nolock) on PerfilUsuario.id = UsuarioContaSistema.idPerfilUsuario;


-- dbo.anapro_atendimentos_midias_dia source

CREATE view [dbo].[anapro_atendimentos_midias_dia] as
select 		
		isnull(INTEGRADORAEXTERNA.Nome, 'OUTROS') as Midia, 
		isnull(Produto.UF, 'XX') AS UF,
		CONVERT(date, SuperEntidade.DtInclusao) as DtInclusao,
		sum(CASE  WHEN Atendimento.idInteracaoNegociacaoVendaUltima IS not NULL THEN 1 else 0 END) as QtdGanho,
		Sum(CASE  WHEN Atendimento.StatusAtendimento = 'ENCERRADO' and Atendimento.idInteracaoNegociacaoVendaUltima IS NULL THEN 1 else 0 END) as QtdPerdido,
		count(Atendimento.id) as Total
		
from 		
Atendimento with (nolock)  		
inner join ContaSistema with (nolock) on ContaSistema.Id = Atendimento.IdContaSistema		
inner join SuperEntidade with (nolock) on SuperEntidade.Id = atendimento.Id		
left outer join Midia with (nolock) on Midia.Id = Atendimento.idMidia		
left outer join INTEGRADORAEXTERNA with (nolock) ON INTEGRADORAEXTERNA.ID = Midia.IdIntegradoraExterna		
LEFT OUTER JOIN Motivacao WITH (NOLOCK) ON Motivacao.ID = Atendimento.IdMotivacaoNaoConversaoVenda
left outer join Produto WITH (NOLOCK) on Produto.Id = Atendimento.idProduto
		
where 		
	SuperEntidade.idContaSistema not in (151, 3, 7, 15, 23, 5, 222, 436)

group by
		isnull(INTEGRADORAEXTERNA.Nome, 'OUTROS'),
		isnull(Produto.UF, 'XX'),
		CONVERT(date, SuperEntidade.DtInclusao);


-- dbo.v_dashboards_atendimentos source

CREATE view [dbo].[v_dashboards_atendimentos] AS

SELECT 
	TabelaoAtendimento.ContaSistemaId, 
	TabelaoAtendimento.AtendimentoId AS AtendimentoCodigo, 
	TabelaoAtendimento.AtendimentoDtInclusao, 
	TabelaoAtendimento.AtendimentoDtInicio,
	TabelaoAtendimento.AtendimentoDtConclusao, 
	TabelaoAtendimento.AtendimentoStatus, 
	TabelaoAtendimento.AtendimentoConvercaoVenda,
	TabelaoAtendimento.AtendimentoConvercaoVendaComputado,
	TabelaoAtendimento.AtendimentoNegociacaoStatus  AS PerdidoOuGanho,
	TabelaoAtendimento.AtendimentoValorNegocio,
	TabelaoAtendimento.AtendimentoComissaoNegocio,
	TabelaoAtendimento.AtendimentoTipoDirecionamento,
	TabelaoAtendimento.AtendimentoQtdDiasSemInteracao,
	TabelaoAtendimento.GrupoId, 
	TabelaoAtendimento.GrupoNome, 
	TabelaoAtendimento.UsuarioContaSistemaId AS UsuarioContaSistemaAtendendoId, 
	TabelaoAtendimento.PessoaNome AS UsuarioContaSistemaAtendendoNome,  
	TabelaoAtendimento.PessoaApelido AS UsuarioContaSistemaAtendendoApelido, 
	TabelaoAtendimento.CriouAtendimentoUsuarioContaSistemaId AS UsuarioContaSistemaIdCriouAtendimento, 
	TabelaoAtendimento.CriouAtendimentoPessoaNome AS UsuarioContaSistemaNomeCriouAtendimento, 
	TabelaoAtendimento.ClassificacaoId AS ClassificacaoFaseId, 
	TabelaoAtendimento.ClassificacaoValor AS ClassificacaoFaseNome,
	TabelaoAtendimento.ClassificacaoValor2  AS ClassificacaoGrupoNome, 
	TabelaoAtendimento.AtendimentoIdMotivacaoNaoConversaoVenda AS MotivacaoNaoConversaoVendaId, 
	TabelaoAtendimento.AtendimentoMotivacaoNaoConversaoVenda AS MotivacaoNaoConversaoVendaNome,
	TabelaoAtendimento.ProdutoId,
	TabelaoAtendimento.ProdutoNome, 
	TabelaoAtendimento.ProdutoUF,
	TabelaoAtendimento.CampanhaId, 
	TabelaoAtendimento.CampanhaNome, 
	TabelaoAtendimento.CanalId, 
	TabelaoAtendimento.CanalNome,
	TabelaoAtendimento.CanalMeio, 
	TabelaoAtendimento.MidiaId, 
	TabelaoAtendimento.MidiaNome,
	TabelaoAtendimento.MidiaTipoValor, 
	TabelaoAtendimento.PecaId, 
	TabelaoAtendimento.PecaNome, 
	TabelaoAtendimento.CampanhaMarketingId, 
	TabelaoAtendimento.CampanhaMarketingNome,
	TabelaoAtendimento.GrupoPecaMarketingId, 
	TabelaoAtendimento.GrupoPecaMarketingNome, 
	TabelaoAtendimento.IntegradoraExternaId, 
	TabelaoAtendimento.IntegradoraExternaNome
FROM TabelaoAtendimento
--WHERE TabelaoAtendimento.AtendimentoDtInclusao > DATEADD(YEAR, -1, GETDATE());


-- dbo.v_dashboards_interacoes source

CREATE VIEW [dbo].[v_dashboards_interacoes] AS
SELECT
	TabelaoInteracaoResumo.IdContaSistema as ContaSistemaId,
	TabelaoInteracaoResumo.IdAtendimento as AtendimentoCodigo,
	TabelaoInteracaoResumo.IdInteracaoTipo,
	TabelaoInteracaoResumo.InteracaoTipoValor as InteracaoTipoNome,
	TabelaoInteracaoResumo.DtInteracao,
	TabelaoInteracaoResumo.DtInteracaoConclusao,
	TabelaoInteracaoResumo.DtInteracaoConclusaoFull,
	TabelaoInteracaoResumo.Periodo as PeriodoInteracaoInclusao,
	TabelaoInteracaoResumo.InteracaoAtorPartida,
	TabelaoInteracaoResumo.DtInteracaoInclusao,
	TabelaoInteracaoResumo.DtInteracaoInclusaoFull,
	TabelaoInteracaoResumo.InteracaoRealizado,
	TabelaoInteracaoResumo.IdMidia,
	TabelaoInteracaoResumo.StrMidia as MidiaNome,
	TabelaoInteracaoResumo.IdPeca,
	TabelaoInteracaoResumo.StrPeca as PecaNome,
	TabelaoInteracaoResumo.IdIntegradoraExterna,
	TabelaoInteracaoResumo.StrIntegradoraExterna as IntegradoraExternaNome,
	TabelaoInteracaoResumo.IdIntegradoraExternaAgencia,
	TabelaoInteracaoResumo.StrIntegradoraExternaAgencia as IntegradoraExternaAgenciaNome,
	TabelaoInteracaoResumo.IdGrupoPecaMarketing,
	TabelaoInteracaoResumo.StrGrupoPecaMarketing as GrupoPecaMarketingNome,
	TabelaoInteracaoResumo.IdCampanhaMarketing,
	TabelaoInteracaoResumo.StrCampanhaMarketing as CampanhaMarketingNome,
	TabelaoInteracaoResumo.IdCanal,
	TabelaoInteracaoResumo.StrCanal as CanalNome,
	TabelaoInteracaoResumo.IdProduto,
	TabelaoInteracaoResumo.StrProdutoNome as ProdutoNome,
	TabelaoInteracaoResumo.AlarmeDt,
	TabelaoInteracaoResumo.AlarmeDtUltimoStatus,
	TabelaoInteracaoResumo.AlarmeStatus,
	TabelaoInteracaoResumo.AlarmeRealizado,
	TabelaoInteracaoResumo.UsuarioContaSistemaRealizouId,
	TabelaoInteracaoResumo.UsuarioContaSistemaRealizouNome,
	TabelaoInteracaoResumo.UsuarioContaSistemaIncluiuId,
	TabelaoInteracaoResumo.UsuarioContaSistemaIncluiuNome
FROM 
	TabelaoInteracaoResumo with(nolock)
WHERE TabelaoInteracaoResumo.DtInteracaoInclusao > DATEADD(YEAR, -1, GETDATE());