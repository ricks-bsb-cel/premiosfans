-- SuperCRMDB.dbo.PessoaProspectIntegracaoLog definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PessoaProspectIntegracaoLog;

CREATE TABLE SuperCRMDB.dbo.PessoaProspectIntegracaoLog (
	Id int IDENTITY(1,1) NOT NULL,
	IdCampanha int NULL,
	IdContaSistema int NOT NULL,
	KeyMaxVendas varchar(50) COLLATE Latin1_General_CI_AI NULL,
	KeyExterno varchar(200) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime NOT NULL,
	URLPost varchar(8000) COLLATE Latin1_General_CI_AI NULL,
	URLRequisitou varchar(8000) COLLATE Latin1_General_CI_AI NULL,
	CanalTipo varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	Tipo varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	KeyMaxVendasCookie varchar(50) COLLATE Latin1_General_CI_AI NULL,
	ProspectNome varchar(600) COLLATE Latin1_General_CI_AI NULL,
	ProspectEmail varchar(600) COLLATE Latin1_General_CI_AI NULL,
	ProspectIP varchar(600) COLLATE Latin1_General_CI_AI NULL,
	IdAtendimento int NULL,
	TagAtalho varchar(300) COLLATE Latin1_General_CI_AI NULL,
	UrlReferrer varchar(5000) COLLATE Latin1_General_CI_AI NULL,
	ProspectBrowser varchar(600) COLLATE Latin1_General_CI_AI NULL,
	ProspectBrowserVersion varchar(600) COLLATE Latin1_General_CI_AI NULL,
	ProspectbrowserMobiledevicemodel varchar(600) COLLATE Latin1_General_CI_AI NULL,
	ProspectBrowserMobileDeviceManufacturer varchar(600) COLLATE Latin1_General_CI_AI NULL,
	ProspectUserAgent varchar(1000) COLLATE Latin1_General_CI_AI NULL,
	ProspectBrowserIsmobiledevice bit DEFAULT 0 NULL,
	ObjAux varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	IdIntegradoraExterna int NULL,
	Versao decimal(18,0) DEFAULT 1 NULL,
	KeyIntegradora varchar(200) COLLATE Latin1_General_CI_AI NULL,
	IdProduto int NULL,
	IdMidia int NULL,
	IdCanal int NULL,
	Obs varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	KeyAgencia varchar(200) COLLATE Latin1_General_CI_AI NULL,
	Outros varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	IdIntegradoraAgencia int NULL,
	IdInteracao int NULL,
	UsuarioEmail varchar(400) COLLATE Latin1_General_CI_AI NULL,
	PostBody varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_PESSOAPROSPECTINTEGRACAOLOG PRIMARY KEY (Id)
);
 CREATE NONCLUSTERED INDEX idxContaSistema ON dbo.PessoaProspectIntegracaoLog (  IdContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxDtInclusao ON dbo.PessoaProspectIntegracaoLog (  DtInclusao ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdAtendimento ON dbo.PessoaProspectIntegracaoLog (  IdAtendimento ASC  , KeyMaxVendas ASC  , KeyExterno ASC  )  
	 INCLUDE ( Id , KeyMaxVendasCookie ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdInteracao ON dbo.PessoaProspectIntegracaoLog (  IdInteracao ASC  , IdAtendimento ASC  )  
	 INCLUDE ( Id , IdCampanha , IdCanal , IdContaSistema , IdIntegradoraExterna , IdMidia , IdProduto ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxKeyExterno ON dbo.PessoaProspectIntegracaoLog (  KeyExterno ASC  , IdAtendimento ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxKeyMaxVendas ON dbo.PessoaProspectIntegracaoLog (  KeyMaxVendas ASC  )  
	 INCLUDE ( Id , IdAtendimento , KeyMaxVendasCookie ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxKeyMaxVendasCookie ON dbo.PessoaProspectIntegracaoLog (  KeyMaxVendasCookie ASC  )  
	 INCLUDE ( Id , IdAtendimento , KeyMaxVendas ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxProspectIP ON dbo.PessoaProspectIntegracaoLog (  ProspectIP ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.TabelaoInteracaoResumo definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.TabelaoInteracaoResumo;

CREATE TABLE SuperCRMDB.dbo.TabelaoInteracaoResumo (
	Id int NOT NULL,
	IdContaSistema int NOT NULL,
	IdAtendimento int NOT NULL,
	IdInteracao int NOT NULL,
	DtInteracao date NOT NULL,
	IdInteracaoTipo int NOT NULL,
	InteracaoTipoValor varchar(200) COLLATE Latin1_General_CI_AI NULL,
	InteracaoTipoValorAbreviado varchar(30) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime NOT NULL,
	DtInteracaoFull datetime NOT NULL,
	Periodo varchar(50) COLLATE Latin1_General_CI_AI NULL,
	IdPessoaProspect int NOT NULL,
	InteracaoAtorPartida varchar(30) COLLATE Latin1_General_CI_AI NULL,
	DtInteracaoInclusao date NOT NULL,
	DtInteracaoInclusaoFull datetime NOT NULL,
	DtInteracaoConclusao date NULL,
	DtInteracaoConclusaoFull datetime NULL,
	InteracaoRealizado char(3) COLLATE Latin1_General_CI_AI NOT NULL,
	IdMidia int NULL,
	IdPeca int NULL,
	IdIntegradoraExterna int NULL,
	IdIntegradoraExternaAgencia int NULL,
	IdGrupoPecaMarketing int NULL,
	IdCampanhaMarketing int NULL,
	IdCanal int NULL,
	StrMidia varchar(500) COLLATE Latin1_General_CI_AI NULL,
	StrPeca varchar(500) COLLATE Latin1_General_CI_AI NULL,
	StrIntegradoraExterna varchar(300) COLLATE Latin1_General_CI_AI NULL,
	StrIntegradoraExternaAgencia varchar(300) COLLATE Latin1_General_CI_AI NULL,
	StrGrupoPecaMarketing varchar(300) COLLATE Latin1_General_CI_AI NULL,
	StrCampanhaMarketing varchar(300) COLLATE Latin1_General_CI_AI NULL,
	StrCanal varchar(300) COLLATE Latin1_General_CI_AI NULL,
	AlarmeDt datetime NULL,
	AlarmeDtUltimoStatus datetime NULL,
	AlarmeStatus char(2) COLLATE Latin1_General_CI_AI NULL,
	AlarmeRealizado bit NULL,
	UsuarioContaSistemaRealizouId int NULL,
	UsuarioContaSistemaIncluiuId int NULL,
	UsuarioContaSistemaRealizouNome varchar(400) COLLATE Latin1_General_CI_AI NULL,
	UsuarioContaSistemaIncluiuNome varchar(400) COLLATE Latin1_General_CI_AI NULL,
	DtAtualizacaoAuto datetime NULL,
	versao varbinary(8) NULL,
	versionIntercao binary(8) NOT NULL,
	versionAtendimento binary(8) NOT NULL,
	UsuarioContaSistemaIncluiuEmail varchar(400) COLLATE Latin1_General_CI_AI NULL,
	UsuarioContaSistemaRealizouEmail varchar(400) COLLATE Latin1_General_CI_AI NULL,
	UsuarioContaSistemaIncluiuApelido varchar(300) COLLATE Latin1_General_CI_AI NULL,
	UsuarioContaSistemaRealizouApelido varchar(300) COLLATE Latin1_General_CI_AI NULL,
	IdProduto int NULL,
	StrProdutoNome varchar(300) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_TabelaoInteracaoResumoAux PRIMARY KEY (IdInteracao)
);
 CREATE NONCLUSTERED INDEX idxDtInclusao ON dbo.TabelaoInteracaoResumo (  DtInclusao ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxDtInteracao ON dbo.TabelaoInteracaoResumo (  DtInteracao DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxDtInteracaoConclusao ON dbo.TabelaoInteracaoResumo (  DtInteracaoConclusao DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxDtInteracaoInclusao ON dbo.TabelaoInteracaoResumo (  DtInteracaoInclusao DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdAtendimento ON dbo.TabelaoInteracaoResumo (  IdAtendimento ASC  , DtAtualizacaoAuto ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdContaSistema , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdCanal ON dbo.TabelaoInteracaoResumo (  IdCanal DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , IdMidia , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdContaSistema2 ON dbo.TabelaoInteracaoResumo (  IdContaSistema ASC  , IdAtendimento ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoRealizado , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdInteracao ON dbo.TabelaoInteracaoResumo (  IdInteracao ASC  , IdAtendimento ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdContaSistema , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdInteracaoTipo ON dbo.TabelaoInteracaoResumo (  IdInteracaoTipo ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdInteracaoWithVersionIntercao ON dbo.TabelaoInteracaoResumo (  IdInteracao ASC  , versionIntercao ASC  )  
	 INCLUDE ( IdAtendimento , IdContaSistema , versionAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdMidia ON dbo.TabelaoInteracaoResumo (  IdMidia DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdPessoaProspect ON dbo.TabelaoInteracaoResumo (  IdPessoaProspect ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxInteracaoTipoValor ON dbo.TabelaoInteracaoResumo (  InteracaoTipoValor ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxUsuarioContaSistemaIncluiuId ON dbo.TabelaoInteracaoResumo (  UsuarioContaSistemaIncluiuId DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxUsuarioContaSistemaRealizouId ON dbo.TabelaoInteracaoResumo (  UsuarioContaSistemaRealizouId DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.TabelaoAtendimento definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.TabelaoAtendimento;

CREATE TABLE SuperCRMDB.dbo.TabelaoAtendimento (
	ContaSistemaId int NOT NULL,
	AtendimentoId int NOT NULL,
	AtendimentoDtInclusao datetime NULL,
	AtendimentoDtInicio datetime NULL,
	AtendimentoStatus varchar(60) COLLATE Latin1_General_CI_AI NULL,
	AtendimentoStatusComputado AS (case when [AtendimentoStatus]='ENCERRADO' then 'ENCERRADO' when [AtendimentoStatus]='ATENDIDO' then 'EM ATENDIMENTO' when [AtendimentoStatus]='AGUARDANDOATENDIMENTO' AND [UsuarioContaSistemaId] IS NOT NULL then 'AGUARDANDO ATENDIMENTO' when [AtendimentoStatus]='AGUARDANDOATENDIMENTO' AND [UsuarioContaSistemaId] IS NULL then 'NA ROLETA' when [AtendimentoStatus]='INCLUIDO' then 'INCLUIDO' else 'NÃO DEFINIDO' end) NOT NULL,
	AtendimentoDtConclusao datetime NULL,
	AtendimentoConvercaoVenda bit NULL,
	AtendimentoConvercaoVendaComputado AS (case [AtendimentoConvercaoVenda] when (1) then 'CONVERTIDO' else 'NÃO CONVERTIDO' end) NOT NULL,
	ProdutoId int NULL,
	ProdutoNome varchar(300) COLLATE Latin1_General_CI_AI NULL,
	ProdutoUF char(2) COLLATE Latin1_General_CI_AI NULL,
	ProdutoMarco varchar(20) COLLATE Latin1_General_CI_AI NULL,
	ProdutoSubList varchar(8000) COLLATE Latin1_General_CI_AI NULL,
	CanalId int NULL,
	CanalNome varchar(300) COLLATE Latin1_General_CI_AI NULL,
	CanalMeio varchar(300) COLLATE Latin1_General_CI_AI NULL,
	MidiaId int NULL,
	MidiaNome varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PecaId int NULL,
	PecaNome varchar(500) COLLATE Latin1_General_CI_AI NULL,
	GrupoId int NULL,
	GrupoNome varchar(100) COLLATE Latin1_General_CI_AI NULL,
	ClassificacaoId int NULL,
	ClassificacaoValor varchar(200) COLLATE Latin1_General_CI_AI NULL,
	CampanhaId int NOT NULL,
	CampanhaNome varchar(50) COLLATE Latin1_General_CI_AI NULL,
	UsuarioContaSistemaId int NULL,
	PessoaId int NULL,
	PessoaNome varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PessoaEmail varchar(300) COLLATE Latin1_General_CI_AI NULL,
	PessoaProspectId int NOT NULL,
	PessoaProspectNome varchar(300) COLLATE Latin1_General_CI_AI NULL,
	PessoaProspectEmailList varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	PessoaProspectTelefoneList varchar(8000) COLLATE Latin1_General_CI_AI NULL,
	PessoaProspectEnderecoList varchar(8000) COLLATE Latin1_General_CI_AI NULL,
	PessoaProspectConsiderarConversao bit NULL,
	PessoaProspectDtInclusao datetime NOT NULL,
	PessoaProspectCPF varchar(50) COLLATE Latin1_General_CI_AI NULL,
	AtendimentoLogIdUltimo int NULL,
	AtendimentoLogUltimoTexto varchar(200) COLLATE Latin1_General_CI_AI NULL,
	AtendimentoLogUltimoDt datetime NULL,
	AtendimentoLogIdPrimeiro int NULL,
	AtendimentoLogPrimeiroTexto varchar(200) COLLATE Latin1_General_CI_AI NULL,
	AtendimentoLogPrimeiroDt datetime NULL,
	AtendimentoLogTodosTexto varchar(200) COLLATE Latin1_General_CI_AI NULL,
	AtendimentoLogInteracaoClienteTodosTexto varchar(200) COLLATE Latin1_General_CI_AI NULL,
	AtendimentoIdMotivacaoNaoConversaoVenda int NULL,
	AtendimentoMotivacaoNaoConversaoVenda varchar(250) COLLATE Latin1_General_CI_AI NULL,
	PessoaProspectIntegracaoLogKeyExterno varchar(36) COLLATE Latin1_General_CI_AI NULL,
	PessoaProspectIntegracaoLogKeyMaxVendas varchar(36) COLLATE Latin1_General_CI_AI NULL,
	MidiaTipoValor varchar(800) COLLATE Latin1_General_CI_AI NULL,
	AtendimentoDtInclusaoDate AS (CONVERT([date],[AtendimentoDtInclusao],(0))),
	AtendimentoDtInicioDate AS (CONVERT([date],[AtendimentoDtInicio],(0))),
	GrupoHierarquia varchar(8000) COLLATE Latin1_General_CI_AI NULL,
	GrupoTag varchar(300) COLLATE Latin1_General_CI_AI NULL,
	GrupoHierarquiaTipo varchar(1000) COLLATE Latin1_General_CI_AI NULL,
	CriouAtendimentoUsuarioContaSistemaId int NULL,
	CriouAtendimentoPessoaNome varchar(200) COLLATE Latin1_General_CI_AI NULL,
	InteracaoPrimeiraId int NULL,
	InteracaoPrimeiraDtFull datetime NULL,
	InteracaoPrimeiraTipoValor varchar(500) COLLATE Latin1_General_CI_AI NULL,
	InteracaoPrimeiraTipoValorAbreviado varchar(500) COLLATE Latin1_General_CI_AI NULL,
	CampanhaMarketingId int NULL,
	CampanhaMarketingNome varchar(500) COLLATE Latin1_General_CI_AI NULL,
	GrupoPecaMarketingId int NULL,
	GrupoPecaMarketingNome varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PessoaProspectSexo char(1) COLLATE Latin1_General_CI_AI NULL,
	AtendimentoTipoDirecionamento varchar(100) COLLATE Latin1_General_CI_AI NULL,
	UsuarioContaSistemaStatus char(2) COLLATE Latin1_General_CI_AI NULL,
	UsuarioContaSistemaStatusComputado AS (case when [UsuarioContaSistemaStatus]='AT' then 'Ativo' else 'Desativado' end) NOT NULL,
	PessoaProspectTagList varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	ClassificacaoOrdem int NULL,
	ProspeccaoNome varchar(200) COLLATE Latin1_General_CI_AI NULL,
	ProspeccaoId int NULL,
	DtInclusao datetime NULL,
	ClassificacaoValor2 varchar(150) COLLATE Latin1_General_CI_AI NULL,
	InteracaoUltimaId int NULL,
	InteracaoUltimaDtFull datetime NULL,
	InteracaoUltimaTipoValor varchar(500) COLLATE Latin1_General_CI_AI NULL,
	InteracaoUltimaTipoValorAbreviado varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PessoaProspectDtNascimento datetime NULL,
	PessoaProspectProfissao varchar(250) COLLATE Latin1_General_CI_AI NULL,
	AtendimentoQtdDiasSemInteracao AS (case when [InteracaoUltimaDtFull] IS NOT NULL AND [AtendimentoStatus]='ATENDIDO' then datediff(day,[InteracaoUltimaDtFull],[dbo].[GetDateCustom]()) else (0) end),
	AtendimentoUltimosUsuariosAtendeu varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	AtendimentoIdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	PessoaProspectIdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	PessoaEnderecoUF1 char(2) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoCidade1 varchar(100) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoBairro1 varchar(100) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoLogradouro1 varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoComplemento1 varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoNumero1 varchar(50) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoCEP1 char(10) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoLatitude1 varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoLongitude1 varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoTipo1 char(3) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoOBS1 varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoUF2 char(2) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoCidade2 varchar(100) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoBairro2 varchar(100) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoLogradouro2 varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoComplemento2 varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoNumero2 varchar(50) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoCEP2 char(10) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoLatitude2 varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoLongitude2 varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoTipo2 char(3) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoOBS2 varchar(500) COLLATE Latin1_General_CI_AI NULL,
	ClassificacaoIdGuid char(36) COLLATE Latin1_General_CI_AI NULL,
	PessoaEmailUltimoQueAtendeu varchar(1500) COLLATE Latin1_General_CI_AI NULL,
	UsuarioContaSistemaIdUltimoQueAtendeu int NULL,
	AtendimentoValorNegocio decimal(18,2) NULL,
	AtendimentoComissaoNegocio decimal(18,2) NULL,
	UsuarioContaSistemaIdGuid char(36) COLLATE Latin1_General_CI_AI NULL,
	ContaSistemaIdGuid char(36) COLLATE Latin1_General_CI_AI NULL,
	InteracaoUltimaDtUtilConsiderar datetime NULL,
	AlarmeUltimoAtivoId int NULL,
	AlarmeUltimoAtivoData datetime NULL,
	AlarmeUltimoAtivoInteracaoTipoValor varchar(300) COLLATE Latin1_General_CI_AI NULL,
	AlarmeProximoAtivoId int NULL,
	AlarmeProximoAtivoData datetime NULL,
	AlarmeProximoAtivoInteracaoTipoValor varchar(300) COLLATE Latin1_General_CI_AI NULL,
	DtAtualizacaoAuto datetime NULL,
	IntegradoraExternaId int NULL,
	IntegradoraExternaIdGuid char(36) COLLATE Latin1_General_CI_AI NULL,
	IntegradoraExternaExtensaoLogo varchar(10) COLLATE Latin1_General_CI_AI NULL,
	IntegradoraExternaNome varchar(200) COLLATE Latin1_General_CI_AI NULL,
	versao varbinary(8) NULL,
	versionAtendimento binary(8) NOT NULL,
	PessoaApelido varchar(300) COLLATE Latin1_General_CI_AI NULL,
	AtendimentoNegociacaoStatus varchar(10) COLLATE Latin1_General_CI_AI DEFAULT 'PADRAO' NOT NULL,
	InteracaoNegociacaoVendaUltimaId int NULL,
	InteracaoNegociacaoVendaUltimaDtFull datetime NULL,
	CONSTRAINT PK_TabelaoAtendimento PRIMARY KEY (AtendimentoId)
);
 CREATE NONCLUSTERED INDEX idxAtendimentoDtConclusao ON dbo.TabelaoAtendimento (  AtendimentoDtConclusao DESC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxAtendimentoDtInclusao ON dbo.TabelaoAtendimento (  AtendimentoDtInclusao DESC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxAtendimentoDtInicio ON dbo.TabelaoAtendimento (  AtendimentoDtInicio DESC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxAtendimentoId ON dbo.TabelaoAtendimento (  AtendimentoId ASC  , DtAtualizacaoAuto ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoStatus , CampanhaId , ContaSistemaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxAtendimentoIdMotivacaoNaoConversaoVenda ON dbo.TabelaoAtendimento (  AtendimentoIdMotivacaoNaoConversaoVenda ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxAtendimentoStatus ON dbo.TabelaoAtendimento (  AtendimentoStatus ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxCampanhaId ON dbo.TabelaoAtendimento (  CampanhaId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxCanalId ON dbo.TabelaoAtendimento (  CanalId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxClassificacaoId ON dbo.TabelaoAtendimento (  ClassificacaoId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , ClassificacaoValor2 , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxContaSistemaId ON dbo.TabelaoAtendimento (  ContaSistemaId ASC  , UsuarioContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxGrupoId ON dbo.TabelaoAtendimento (  GrupoId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxMidiaId ON dbo.TabelaoAtendimento (  MidiaId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PecaId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxPessoaProspectId ON dbo.TabelaoAtendimento (  PessoaProspectId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxProdutoId ON dbo.TabelaoAtendimento (  ProdutoId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxProdutoUF ON dbo.TabelaoAtendimento (  ProdutoUF ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxUniqueId ON dbo.TabelaoAtendimento (  AtendimentoId ASC  )  
	 INCLUDE ( ContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxUsuarioContaSistemaId ON dbo.TabelaoAtendimento (  UsuarioContaSistemaId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Evento definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Evento;

CREATE TABLE SuperCRMDB.dbo.Evento (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdContaSistema int NULL,
	IdEventoPre int NOT NULL,
	EventoTipo varchar(100) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	ObjAcaoType varchar(400) COLLATE Latin1_General_CI_AI NULL,
	ObjJson varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	ObjTipo varchar(200) COLLATE Latin1_General_CI_AI NOT NULL,
	Processado bit NOT NULL,
	DtProcessado datetime NULL,
	Status char(3) COLLATE Latin1_General_CI_AI DEFAULT 'INC' NULL,
	QtdTentativaProcessamento int DEFAULT 0 NOT NULL,
	AvisarAdmOnError bit DEFAULT 0 NOT NULL,
	GrupoProcessamento varchar(100) COLLATE Latin1_General_CI_AI NULL,
	TimeProcessamentoSeg int DEFAULT 0 NULL,
	HrValidadeProcessamentoInicio time NULL,
	HrValidadeProcessamentoFim time NULL,
	DtValidadeInicio datetime NOT NULL,
	ObjJsonLog varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_EVENTO PRIMARY KEY (Id)
);
 CREATE NONCLUSTERED INDEX idxGrupoProcessamento ON dbo.Evento (  GrupoProcessamento ASC  , Processado ASC  , Status ASC  )  
	 INCLUDE ( DtValidadeInicio , HrValidadeProcessamentoFim , HrValidadeProcessamentoInicio , ObjAcaoType , ObjTipo , QtdTentativaProcessamento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.EventoPre definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.EventoPre;

CREATE TABLE SuperCRMDB.dbo.EventoPre (
	Id int IDENTITY(1,1) NOT NULL,
	EventoTipo varchar(100) COLLATE Latin1_General_CI_AI NOT NULL,
	Status char(3) COLLATE Latin1_General_CI_AI NOT NULL,
	Processado bit NOT NULL,
	DtInclusao datetime NOT NULL,
	DtProcessado datetime NULL,
	ObjVersao smallint NOT NULL,
	ObjTipo varchar(250) COLLATE Latin1_General_CI_AI NOT NULL,
	ObjJson varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	Log varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_EVENTOPRE PRIMARY KEY (Id)
);
 CREATE NONCLUSTERED INDEX idxProcessado ON dbo.EventoPre (  Processado ASC  , Id ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.EnrichPerson definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.EnrichPerson;

CREATE TABLE SuperCRMDB.dbo.EnrichPerson (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	DtAtualizacao datetime NOT NULL,
	Tipo varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	ObjSerializado varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_ENRICHPERSON PRIMARY KEY (Id)
);


-- SuperCRMDB.dbo.Pessoa definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Pessoa;

CREATE TABLE SuperCRMDB.dbo.Pessoa (
	Id int IDENTITY(1,1) NOT NULL,
	Guid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	TipoPessoa char(1) COLLATE Latin1_General_CI_AI NOT NULL,
	Nome varchar(500) COLLATE Latin1_General_CI_AI NOT NULL,
	Email varchar(300) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime DEFAULT [dbo].[GetDateCustom]() NULL,
	DtModificacao datetime DEFAULT [dbo].[GetDateCustom]() NULL,
	Obs varchar(500) COLLATE Latin1_General_CI_AI NULL,
	Apelido varchar(300) COLLATE Latin1_General_CI_AI NULL,
	versao timestamp NOT NULL,
	CONSTRAINT PK_PESSOA PRIMARY KEY (Id)
);
 CREATE NONCLUSTERED INDEX idxEmail ON dbo.Pessoa (  Email ASC  , Nome ASC  )  
	 INCLUDE ( Guid , Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.Pessoa (  Guid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxNome ON dbo.Pessoa (  Nome ASC  , Email ASC  )  
	 INCLUDE ( Guid , Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
ALTER TABLE SuperCRMDB.dbo.Pessoa WITH NOCHECK ADD CONSTRAINT CKC_TIPOPESSOA_PESSOA CHECK (([TipoPessoa]='J' OR [TipoPessoa]='F') AND ([TipoPessoa]='J' OR [TipoPessoa]='F') AND ([TipoPessoa]='J' OR [TipoPessoa]='F'));


-- SuperCRMDB.dbo.Bookmark definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Bookmark;

CREATE TABLE SuperCRMDB.dbo.Bookmark (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdContaSistema int NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	Nome nvarchar(150) COLLATE Latin1_General_CI_AI NOT NULL,
	DtCriacao datetime NOT NULL,
	ObjVersao int NOT NULL,
	ObjTipo varchar(300) COLLATE Latin1_General_CI_AI NOT NULL,
	ObjJson nvarchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	Tipo varchar(20) COLLATE Latin1_General_CI_AI NOT NULL,
	ReadOnlySys bit NOT NULL,
	CONSTRAINT PK_BOOKMARK PRIMARY KEY (Id)
);
 CREATE NONCLUSTERED INDEX idxIdUsuarioContaSistema ON dbo.Bookmark (  IdUsuarioContaSistema ASC  , IdContaSistema ASC  )  
	 INCLUDE ( Id , ReadOnlySys , Tipo ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
ALTER TABLE SuperCRMDB.dbo.Bookmark WITH NOCHECK ADD CONSTRAINT CKC_OBJJSON_BOOKMARK CHECK ([ObjJson] IS NULL OR isjson([Bookmark].[ObjJson])=(1));


-- SuperCRMDB.dbo.PesquisaNPSFull definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PesquisaNPSFull;

CREATE TABLE SuperCRMDB.dbo.PesquisaNPSFull (
	Name nvarchar(255) COLLATE Latin1_General_CI_AI NULL,
	Firstname nvarchar(255) COLLATE Latin1_General_CI_AI NULL,
	Lastname nvarchar(255) COLLATE Latin1_General_CI_AI NULL,
	Email nvarchar(255) COLLATE Latin1_General_CI_AI NULL,
	UserID nvarchar(255) COLLATE Latin1_General_CI_AI NULL,
	[Data] smalldatetime NULL,
	Score float NULL,
	Feedback nvarchar(255) COLLATE Latin1_General_CI_AI NULL,
	Linguagem nvarchar(255) COLLATE Latin1_General_CI_AI NULL,
	RefURL nvarchar(255) COLLATE Latin1_General_CI_AI NULL,
	Browser nvarchar(255) COLLATE Latin1_General_CI_AI NULL,
	OS nvarchar(255) COLLATE Latin1_General_CI_AI NULL,
	City nvarchar(255) COLLATE Latin1_General_CI_AI NULL,
	Country nvarchar(255) COLLATE Latin1_General_CI_AI NULL,
	Host nvarchar(255) COLLATE Latin1_General_CI_AI NULL,
	User_created_at smalldatetime NULL,
	Codigo varchar(600) COLLATE Latin1_General_CI_AI NULL
);


-- SuperCRMDB.dbo.PendenciaProcessamentoLog definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PendenciaProcessamentoLog;

CREATE TABLE SuperCRMDB.dbo.PendenciaProcessamentoLog (
	Id int IDENTITY(1,1) NOT NULL,
	IdPendenciaProcessamento int NOT NULL,
	Tipo varchar(30) COLLATE Latin1_General_CI_AI NOT NULL,
	Obs varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime NOT NULL,
	[Exception] varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	ExceptionInner varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	ExceptionMessage varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_PENDENCIAPROCESSAMENTOLOG PRIMARY KEY (Id)
);
 CREATE NONCLUSTERED INDEX idxIdPendenciaProcessamento ON dbo.PendenciaProcessamentoLog (  IdPendenciaProcessamento ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.PesquisaNPSAdjetivo definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PesquisaNPSAdjetivo;

CREATE TABLE SuperCRMDB.dbo.PesquisaNPSAdjetivo (
	Id int IDENTITY(1,1) NOT NULL,
	Valor nvarchar(500) COLLATE Latin1_General_CI_AI NULL
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxValor ON dbo.PesquisaNPSAdjetivo (  Valor ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.ContaSistema definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.ContaSistema;

CREATE TABLE SuperCRMDB.dbo.ContaSistema (
	Id int IDENTITY(1,1) NOT NULL,
	Nome varchar(300) COLLATE Latin1_General_CI_AI NOT NULL,
	Guid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime DEFAULT [dbo].[GetDateCustom]() NOT NULL,
	StatusConta char(2) COLLATE Latin1_General_CI_AI DEFAULT 'AT' NOT NULL,
	GuidCorrex char(36) COLLATE Latin1_General_CI_AI NULL,
	DtCancelamento datetime NULL,
	versao timestamp NOT NULL,
	CONSTRAINT PK_CONTASISTEMA PRIMARY KEY (Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.ContaSistema (  Guid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxGuidCorrex ON dbo.ContaSistema (  GuidCorrex ASC  )  
	 WHERE  ([GuidCorrex] IS NOT NULL)
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Log definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Log;

CREATE TABLE SuperCRMDB.dbo.Log (
	Id int IDENTITY(1,1) NOT NULL,
	[Date] datetime NOT NULL,
	Thread varchar(250) COLLATE Latin1_General_CI_AI NOT NULL,
	[Level] varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	Logger varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	Message varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	[Exception] varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_LOG PRIMARY KEY (Id)
);


-- SuperCRMDB.dbo.MailMask definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.MailMask;

CREATE TABLE SuperCRMDB.dbo.MailMask (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	Codigo varchar(300) COLLATE Latin1_General_CI_AI NOT NULL,
	Template varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	DtModificacao datetime NULL,
	CONSTRAINT PK_MAILMASK PRIMARY KEY (Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDX ON dbo.MailMask (  Codigo ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.TemplateIntegracao definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.TemplateIntegracao;

CREATE TABLE SuperCRMDB.dbo.TemplateIntegracao (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	Nome varchar(400) COLLATE Latin1_General_CI_AI NOT NULL,
	HttpMethod varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	ClassTranslator varchar(1000) COLLATE Latin1_General_CI_AI NOT NULL,
	Template varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	ExemploObjTraducao varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	TipoObjSerializadoPartida varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	ExemploObjPartida varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime NOT NULL,
	ExemploQueryStringPartida varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	Tipo varchar(100) COLLATE Latin1_General_CI_AI DEFAULT 'CADASTROPROSPECT' NOT NULL,
	TipoObjSerializadoPartidaResponse varchar(50) COLLATE Latin1_General_CI_AI NULL,
	ExemploObjPartidaResponse varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	TemplateResponse varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	ClassObjAuxPartidaTranslator varchar(1000) COLLATE Latin1_General_CI_AI NULL,
	ExemploObjAuxPartida varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	CodigoInterno varchar(200) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	ObjJson varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_TEMPLATEINTEGRACAO PRIMARY KEY (Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxCodigoInterno ON dbo.TemplateIntegracao (  CodigoInterno ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.TemplateIntegracao (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
ALTER TABLE SuperCRMDB.dbo.TemplateIntegracao WITH NOCHECK ADD CONSTRAINT CKC_OBJJSON_TemplateIntegracao CHECK ([ObjJson] IS NULL OR isjson([TemplateIntegracao].[ObjJson])=(1));


-- SuperCRMDB.dbo.PesquisaNPSPalavraNaoIgnore definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PesquisaNPSPalavraNaoIgnore;

CREATE TABLE SuperCRMDB.dbo.PesquisaNPSPalavraNaoIgnore (
	Id int IDENTITY(1,1) NOT NULL,
	Valor nvarchar(500) COLLATE Latin1_General_CI_AI NULL
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxValor ON dbo.PesquisaNPSPalavraNaoIgnore (  Valor ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.EventoTipo definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.EventoTipo;

CREATE TABLE SuperCRMDB.dbo.EventoTipo (
	Tipo varchar(100) COLLATE Latin1_General_CI_AI NOT NULL,
	Nome varchar(200) COLLATE Latin1_General_CI_AI NOT NULL,
	Obs varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime NOT NULL,
	Publico bit DEFAULT 1 NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	TipoCriacao varchar(100) COLLATE Latin1_General_CI_AI DEFAULT 'AUTOMATICO' NOT NULL,
	TipoExecucao varchar(100) COLLATE Latin1_General_CI_AI DEFAULT 'AUTOMATICO' NOT NULL,
	GrupoProcessamento varchar(100) COLLATE Latin1_General_CI_AI NULL,
	HrValidadeProcessamentoInicio time NULL,
	HrValidadeProcessamentoFim time NULL,
	CONSTRAINT PK_EVENTOTIPO PRIMARY KEY (Tipo)
);
 CREATE  UNIQUE NONCLUSTERED INDEX idx1 ON dbo.EventoTipo (  Tipo ASC  , Status ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Card definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Card;

CREATE TABLE SuperCRMDB.dbo.Card (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	DtInclusao datetime NOT NULL,
	Titulo varchar(300) COLLATE Latin1_General_CI_AI NOT NULL,
	Descricao varchar(800) COLLATE Latin1_General_CI_AI NOT NULL,
	ObjTipo varchar(400) COLLATE Latin1_General_CI_AI NOT NULL,
	ObjJson varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_CARD PRIMARY KEY (Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.Card (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Acao definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Acao;

CREATE TABLE SuperCRMDB.dbo.Acao (
	Id int IDENTITY(1,1) NOT NULL,
	Nome varchar(300) COLLATE Latin1_General_CI_AI NOT NULL,
	Obs varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	ObjType varchar(400) COLLATE Latin1_General_CI_AI NOT NULL,
	TipoExecucao varchar(100) COLLATE Latin1_General_CI_AI DEFAULT 'CSHARP' NOT NULL,
	Publico bit DEFAULT 1 NOT NULL,
	CONSTRAINT PK_ACAO PRIMARY KEY (Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxObjType ON dbo.Acao (  ObjType ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.EnrichPersonDataSource definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.EnrichPersonDataSource;

CREATE TABLE SuperCRMDB.dbo.EnrichPersonDataSource (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	Nome varchar(300) COLLATE Latin1_General_CI_AI NOT NULL,
	Tipo varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_ENRICHPERSONDATASOURCE PRIMARY KEY (Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.EnrichPersonDataSource (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxTipo ON dbo.EnrichPersonDataSource (  Tipo ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.PesquisaNPSPalavraIgnore definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PesquisaNPSPalavraIgnore;

CREATE TABLE SuperCRMDB.dbo.PesquisaNPSPalavraIgnore (
	Id int IDENTITY(1,1) NOT NULL,
	Valor nvarchar(500) COLLATE Latin1_General_CI_AI NULL
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxValor ON dbo.PesquisaNPSPalavraIgnore (  Valor ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Dashboard definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Dashboard;

CREATE TABLE SuperCRMDB.dbo.Dashboard (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	DtInclusao datetime NOT NULL,
	Titulo varchar(300) COLLATE Latin1_General_CI_AI NOT NULL,
	Descricao varchar(800) COLLATE Latin1_General_CI_AI NOT NULL,
	ObjTipo varchar(400) COLLATE Latin1_General_CI_AI NOT NULL,
	ObjJson varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_DASHBOARD PRIMARY KEY (Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.Dashboard (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.DbLocalidadeUF definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.DbLocalidadeUF;

CREATE TABLE SuperCRMDB.dbo.DbLocalidadeUF (
	Sigla char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	Nome varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_X_UF PRIMARY KEY (Sigla)
);
 CREATE  UNIQUE NONCLUSTERED INDEX idx1 ON dbo.DbLocalidadeUF (  Sigla ASC  )  
	 INCLUDE ( Nome ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
ALTER TABLE SuperCRMDB.dbo.DbLocalidadeUF WITH NOCHECK ADD CONSTRAINT CKC_SIGLA_UF CHECK ([Sigla]=upper([Sigla]));


-- SuperCRMDB.dbo.ModuloSistema definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.ModuloSistema;

CREATE TABLE SuperCRMDB.dbo.ModuloSistema (
	Id int IDENTITY(1,1) NOT NULL,
	Nome varchar(1000) COLLATE Latin1_General_CI_AI NOT NULL,
	Codigo varchar(100) COLLATE Latin1_General_CI_AI NOT NULL,
	Padrao bit DEFAULT 0 NOT NULL,
	CONSTRAINT PK_MODULOSISTEMA PRIMARY KEY (Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxCodigo ON dbo.ModuloSistema (  Codigo ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.RelatorioGrupo definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.RelatorioGrupo;

CREATE TABLE SuperCRMDB.dbo.RelatorioGrupo (
	Id int IDENTITY(1,1) NOT NULL,
	Nome varchar(300) COLLATE Latin1_General_CI_AI NOT NULL,
	Descricao varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime DEFAULT [dbo].[GetDateCustom]() NOT NULL,
	CONSTRAINT PK_RELATORIOGRUPO PRIMARY KEY (Id)
);


-- SuperCRMDB.dbo.TabelaoLog definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.TabelaoLog;

CREATE TABLE SuperCRMDB.dbo.TabelaoLog (
	Id int IDENTITY(1,1) NOT NULL,
	Nome varchar(1000) COLLATE Latin1_General_CI_AI NOT NULL,
	Data1 datetime NULL,
	Data2 datetime NULL,
	String1 varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	String2 varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	Texto1 varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	Texto2 varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	Numero1 int NULL,
	Numero2 int NULL,
	Bit1 bit NULL,
	Bit2 bit NULL,
	Obj varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime NOT NULL,
	DtUltimaParcial datetime NOT NULL,
	DtUltimaCompleta datetime NOT NULL,
	ObjTipo varchar(400) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_MAXVENDASCONF PRIMARY KEY (Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDXNOMEUNIQUE ON dbo.TabelaoLog (  Nome ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Teste definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Teste;

CREATE TABLE SuperCRMDB.dbo.Teste (
	Id int IDENTITY(1,1) NOT NULL,
	Texto varchar(200) COLLATE Latin1_General_CI_AI NULL,
	DtInsercao datetime NULL,
	Guid char(36) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_Teste PRIMARY KEY (Id)
);
 CREATE NONCLUSTERED INDEX idx ON dbo.Teste (  Guid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.SuperEntidadeTipo definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.SuperEntidadeTipo;

CREATE TABLE SuperCRMDB.dbo.SuperEntidadeTipo (
	SuperEntidadeTipo varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	Nome varchar(150) COLLATE Latin1_General_CI_AI NOT NULL,
	Descricao varchar(300) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_SUPERENTIDADETIPO PRIMARY KEY (SuperEntidadeTipo)
);
ALTER TABLE SuperCRMDB.dbo.SuperEntidadeTipo WITH NOCHECK ADD CONSTRAINT CKC_SUPERENTIDADETIPO_SUPERENT CHECK ([SuperEntidadeTipo]=upper([SuperEntidadeTipo]));


-- SuperCRMDB.dbo.UF1 definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.UF1;

CREATE TABLE SuperCRMDB.dbo.UF1 (
	Sigla char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	Nome varchar(80) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_UF PRIMARY KEY (Sigla)
);


-- SuperCRMDB.dbo.LogGeral definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.LogGeral;

CREATE TABLE SuperCRMDB.dbo.LogGeral (
	Id int IDENTITY(1,1) NOT NULL,
	DtInclusao datetime NOT NULL,
	Texto varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_LOGGERAL PRIMARY KEY (Id)
);


-- SuperCRMDB.dbo.TabelaoAtendimentoAux definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.TabelaoAtendimentoAux;

CREATE TABLE SuperCRMDB.dbo.TabelaoAtendimentoAux (
	ContaSistemaId int NOT NULL,
	AtendimentoId int NOT NULL,
	AtendimentoDtInclusao datetime NULL,
	AtendimentoDtInicio datetime NULL,
	AtendimentoStatus varchar(60) COLLATE Latin1_General_CI_AI NULL,
	AtendimentoStatusComputado AS (case when [AtendimentoStatus]='ENCERRADO' then 'ENCERRADO' when [AtendimentoStatus]='ATENDIDO' then 'EM ATENDIMENTO' when [AtendimentoStatus]='AGUARDANDOATENDIMENTO' AND [UsuarioContaSistemaId] IS NOT NULL then 'AGUARDANDO ATENDIMENTO' when [AtendimentoStatus]='AGUARDANDOATENDIMENTO' AND [UsuarioContaSistemaId] IS NULL then 'NA ROLETA' when [AtendimentoStatus]='INCLUIDO' then 'INCLUIDO' else 'NÃO DEFINIDO' end) NOT NULL,
	AtendimentoDtConclusao datetime NULL,
	AtendimentoConvercaoVenda bit NULL,
	AtendimentoConvercaoVendaComputado AS (case [AtendimentoConvercaoVenda] when (1) then 'CONVERTIDO' else 'NÃO CONVERTIDO' end) NOT NULL,
	ProdutoId int NULL,
	ProdutoNome varchar(300) COLLATE Latin1_General_CI_AI NULL,
	ProdutoUF char(2) COLLATE Latin1_General_CI_AI NULL,
	ProdutoMarco varchar(20) COLLATE Latin1_General_CI_AI NULL,
	ProdutoSubList varchar(8000) COLLATE Latin1_General_CI_AI NULL,
	CanalId int NULL,
	CanalNome varchar(300) COLLATE Latin1_General_CI_AI NULL,
	CanalMeio varchar(300) COLLATE Latin1_General_CI_AI NULL,
	MidiaId int NULL,
	MidiaNome varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PecaId int NULL,
	PecaNome varchar(500) COLLATE Latin1_General_CI_AI NULL,
	GrupoId int NULL,
	GrupoNome varchar(100) COLLATE Latin1_General_CI_AI NULL,
	ClassificacaoId int NULL,
	ClassificacaoValor varchar(200) COLLATE Latin1_General_CI_AI NULL,
	CampanhaId int NOT NULL,
	CampanhaNome varchar(50) COLLATE Latin1_General_CI_AI NULL,
	UsuarioContaSistemaId int NULL,
	PessoaId int NULL,
	PessoaNome varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PessoaEmail varchar(300) COLLATE Latin1_General_CI_AI NULL,
	PessoaProspectId int NOT NULL,
	PessoaProspectNome varchar(300) COLLATE Latin1_General_CI_AI NULL,
	PessoaProspectEmailList varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	PessoaProspectTelefoneList varchar(8000) COLLATE Latin1_General_CI_AI NULL,
	PessoaProspectEnderecoList varchar(8000) COLLATE Latin1_General_CI_AI NULL,
	PessoaProspectConsiderarConversao bit NULL,
	PessoaProspectDtInclusao datetime NOT NULL,
	PessoaProspectCPF varchar(50) COLLATE Latin1_General_CI_AI NULL,
	AtendimentoLogIdUltimo int NULL,
	AtendimentoLogUltimoTexto varchar(200) COLLATE Latin1_General_CI_AI NULL,
	AtendimentoLogUltimoDt datetime NULL,
	AtendimentoLogIdPrimeiro int NULL,
	AtendimentoLogPrimeiroTexto varchar(200) COLLATE Latin1_General_CI_AI NULL,
	AtendimentoLogPrimeiroDt datetime NULL,
	AtendimentoLogTodosTexto varchar(200) COLLATE Latin1_General_CI_AI NULL,
	AtendimentoLogInteracaoClienteTodosTexto varchar(200) COLLATE Latin1_General_CI_AI NULL,
	AtendimentoIdMotivacaoNaoConversaoVenda int NULL,
	AtendimentoMotivacaoNaoConversaoVenda varchar(250) COLLATE Latin1_General_CI_AI NULL,
	PessoaProspectIntegracaoLogKeyExterno varchar(36) COLLATE Latin1_General_CI_AI NULL,
	PessoaProspectIntegracaoLogKeyMaxVendas varchar(36) COLLATE Latin1_General_CI_AI NULL,
	MidiaTipoValor varchar(800) COLLATE Latin1_General_CI_AI NULL,
	AtendimentoDtInclusaoDate AS (CONVERT([date],[AtendimentoDtInclusao],(0))),
	AtendimentoDtInicioDate AS (CONVERT([date],[AtendimentoDtInicio],(0))),
	GrupoHierarquia varchar(8000) COLLATE Latin1_General_CI_AI NULL,
	GrupoTag varchar(300) COLLATE Latin1_General_CI_AI NULL,
	GrupoHierarquiaTipo varchar(1000) COLLATE Latin1_General_CI_AI NULL,
	CriouAtendimentoUsuarioContaSistemaId int NULL,
	CriouAtendimentoPessoaNome varchar(200) COLLATE Latin1_General_CI_AI NULL,
	InteracaoPrimeiraId int NULL,
	InteracaoPrimeiraDtFull datetime NULL,
	InteracaoPrimeiraTipoValor varchar(500) COLLATE Latin1_General_CI_AI NULL,
	InteracaoPrimeiraTipoValorAbreviado varchar(500) COLLATE Latin1_General_CI_AI NULL,
	CampanhaMarketingId int NULL,
	CampanhaMarketingNome varchar(500) COLLATE Latin1_General_CI_AI NULL,
	GrupoPecaMarketingId int NULL,
	GrupoPecaMarketingNome varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PessoaProspectSexo char(1) COLLATE Latin1_General_CI_AI NULL,
	AtendimentoTipoDirecionamento varchar(100) COLLATE Latin1_General_CI_AI NULL,
	UsuarioContaSistemaStatus char(2) COLLATE Latin1_General_CI_AI NULL,
	UsuarioContaSistemaStatusComputado AS (case when [UsuarioContaSistemaStatus]='AT' then 'Ativo' else 'Desativado' end) NOT NULL,
	PessoaProspectTagList varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	ClassificacaoOrdem int NULL,
	ProspeccaoNome varchar(200) COLLATE Latin1_General_CI_AI NULL,
	ProspeccaoId int NULL,
	DtInclusao datetime NULL,
	ClassificacaoValor2 varchar(150) COLLATE Latin1_General_CI_AI NULL,
	InteracaoUltimaId int NULL,
	InteracaoUltimaDtFull datetime NULL,
	InteracaoUltimaTipoValor varchar(500) COLLATE Latin1_General_CI_AI NULL,
	InteracaoUltimaTipoValorAbreviado varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PessoaProspectDtNascimento datetime NULL,
	PessoaProspectProfissao varchar(250) COLLATE Latin1_General_CI_AI NULL,
	AtendimentoQtdDiasSemInteracao AS (case when [InteracaoUltimaDtFull] IS NOT NULL AND [AtendimentoStatus]='ATENDIDO' then datediff(day,[InteracaoUltimaDtFull],[dbo].[GetDateCustom]()) else (0) end),
	AtendimentoUltimosUsuariosAtendeu varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	AtendimentoIdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	PessoaProspectIdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	PessoaEnderecoUF1 char(2) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoCidade1 varchar(100) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoBairro1 varchar(100) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoLogradouro1 varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoComplemento1 varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoNumero1 varchar(50) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoCEP1 char(10) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoLatitude1 varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoLongitude1 varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoTipo1 char(3) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoOBS1 varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoUF2 char(2) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoCidade2 varchar(100) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoBairro2 varchar(100) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoLogradouro2 varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoComplemento2 varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoNumero2 varchar(50) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoCEP2 char(10) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoLatitude2 varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoLongitude2 varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoTipo2 char(3) COLLATE Latin1_General_CI_AI NULL,
	PessoaEnderecoOBS2 varchar(500) COLLATE Latin1_General_CI_AI NULL,
	ClassificacaoIdGuid char(36) COLLATE Latin1_General_CI_AI NULL,
	PessoaEmailUltimoQueAtendeu varchar(1500) COLLATE Latin1_General_CI_AI NULL,
	UsuarioContaSistemaIdUltimoQueAtendeu int NULL,
	AtendimentoValorNegocio decimal(18,2) NULL,
	AtendimentoComissaoNegocio decimal(18,2) NULL,
	UsuarioContaSistemaIdGuid char(36) COLLATE Latin1_General_CI_AI NULL,
	ContaSistemaIdGuid char(36) COLLATE Latin1_General_CI_AI NULL,
	InteracaoUltimaDtUtilConsiderar datetime NULL,
	AlarmeUltimoAtivoId int NULL,
	AlarmeUltimoAtivoData datetime NULL,
	AlarmeUltimoAtivoInteracaoTipoValor varchar(300) COLLATE Latin1_General_CI_AI NULL,
	AlarmeProximoAtivoId int NULL,
	AlarmeProximoAtivoData datetime NULL,
	AlarmeProximoAtivoInteracaoTipoValor varchar(300) COLLATE Latin1_General_CI_AI NULL,
	DtAtualizacaoAuto datetime NULL,
	IntegradoraExternaId int NULL,
	IntegradoraExternaIdGuid char(36) COLLATE Latin1_General_CI_AI NULL,
	IntegradoraExternaExtensaoLogo varchar(10) COLLATE Latin1_General_CI_AI NULL,
	IntegradoraExternaNome varchar(200) COLLATE Latin1_General_CI_AI NULL,
	versao varbinary(8) NULL,
	versionAtendimento binary(8) NOT NULL,
	PessoaApelido varchar(300) COLLATE Latin1_General_CI_AI NULL,
	AtendimentoNegociacaoStatus varchar(10) COLLATE Latin1_General_CI_AI DEFAULT 'PADRAO' NOT NULL,
	InteracaoNegociacaoVendaUltimaId int NULL,
	InteracaoNegociacaoVendaUltimaDtFull datetime NULL,
	CONSTRAINT PK_TabelaoAtendimentoAux PRIMARY KEY (AtendimentoId)
);
 CREATE NONCLUSTERED INDEX idxAtendimentoDtConclusao ON dbo.TabelaoAtendimentoAux (  AtendimentoDtConclusao DESC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxAtendimentoDtInclusao ON dbo.TabelaoAtendimentoAux (  AtendimentoDtInclusao DESC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxAtendimentoDtInicio ON dbo.TabelaoAtendimentoAux (  AtendimentoDtInicio DESC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxAtendimentoId ON dbo.TabelaoAtendimentoAux (  AtendimentoId ASC  , DtAtualizacaoAuto ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoStatus , CampanhaId , ContaSistemaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxAtendimentoIdMotivacaoNaoConversaoVenda ON dbo.TabelaoAtendimentoAux (  AtendimentoIdMotivacaoNaoConversaoVenda ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxAtendimentoStatus ON dbo.TabelaoAtendimentoAux (  AtendimentoStatus ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxCampanhaId ON dbo.TabelaoAtendimentoAux (  CampanhaId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxCanalId ON dbo.TabelaoAtendimentoAux (  CanalId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxClassificacaoId ON dbo.TabelaoAtendimentoAux (  ClassificacaoId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , ClassificacaoValor2 , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxContaSistemaId ON dbo.TabelaoAtendimentoAux (  ContaSistemaId ASC  , UsuarioContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxGrupoId ON dbo.TabelaoAtendimentoAux (  GrupoId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxMidiaId ON dbo.TabelaoAtendimentoAux (  MidiaId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PecaId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxPessoaProspectId ON dbo.TabelaoAtendimentoAux (  PessoaProspectId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxProdutoId ON dbo.TabelaoAtendimentoAux (  ProdutoId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxProdutoUF ON dbo.TabelaoAtendimentoAux (  ProdutoUF ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxUniqueId ON dbo.TabelaoAtendimentoAux (  AtendimentoId ASC  )  
	 INCLUDE ( ContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxUsuarioContaSistemaId ON dbo.TabelaoAtendimentoAux (  UsuarioContaSistemaId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.TabelaoInteracaoResumoAux definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.TabelaoInteracaoResumoAux;

CREATE TABLE SuperCRMDB.dbo.TabelaoInteracaoResumoAux (
	Id int NOT NULL,
	IdContaSistema int NOT NULL,
	IdAtendimento int NOT NULL,
	IdInteracao int NOT NULL,
	DtInteracao date NOT NULL,
	IdInteracaoTipo int NOT NULL,
	InteracaoTipoValor varchar(200) COLLATE Latin1_General_CI_AI NULL,
	InteracaoTipoValorAbreviado varchar(30) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime NOT NULL,
	DtInteracaoFull datetime NOT NULL,
	Periodo varchar(50) COLLATE Latin1_General_CI_AI NULL,
	IdPessoaProspect int NOT NULL,
	InteracaoAtorPartida varchar(30) COLLATE Latin1_General_CI_AI NULL,
	DtInteracaoInclusao date NOT NULL,
	DtInteracaoInclusaoFull datetime NOT NULL,
	DtInteracaoConclusao date NULL,
	DtInteracaoConclusaoFull datetime NULL,
	InteracaoRealizado char(3) COLLATE Latin1_General_CI_AI NOT NULL,
	IdMidia int NULL,
	IdPeca int NULL,
	IdIntegradoraExterna int NULL,
	IdIntegradoraExternaAgencia int NULL,
	IdGrupoPecaMarketing int NULL,
	IdCampanhaMarketing int NULL,
	IdCanal int NULL,
	StrMidia varchar(500) COLLATE Latin1_General_CI_AI NULL,
	StrPeca varchar(500) COLLATE Latin1_General_CI_AI NULL,
	StrIntegradoraExterna varchar(300) COLLATE Latin1_General_CI_AI NULL,
	StrIntegradoraExternaAgencia varchar(300) COLLATE Latin1_General_CI_AI NULL,
	StrGrupoPecaMarketing varchar(300) COLLATE Latin1_General_CI_AI NULL,
	StrCampanhaMarketing varchar(300) COLLATE Latin1_General_CI_AI NULL,
	StrCanal varchar(300) COLLATE Latin1_General_CI_AI NULL,
	AlarmeDt datetime NULL,
	AlarmeDtUltimoStatus datetime NULL,
	AlarmeStatus char(2) COLLATE Latin1_General_CI_AI NULL,
	AlarmeRealizado bit NULL,
	UsuarioContaSistemaRealizouId int NULL,
	UsuarioContaSistemaIncluiuId int NULL,
	UsuarioContaSistemaRealizouNome varchar(400) COLLATE Latin1_General_CI_AI NULL,
	UsuarioContaSistemaIncluiuNome varchar(400) COLLATE Latin1_General_CI_AI NULL,
	DtAtualizacaoAuto datetime NULL,
	versao varbinary(8) NULL,
	versionIntercao binary(8) NOT NULL,
	versionAtendimento binary(8) NOT NULL,
	UsuarioContaSistemaIncluiuEmail varchar(400) COLLATE Latin1_General_CI_AI NULL,
	UsuarioContaSistemaRealizouEmail varchar(400) COLLATE Latin1_General_CI_AI NULL,
	UsuarioContaSistemaIncluiuApelido varchar(300) COLLATE Latin1_General_CI_AI NULL,
	UsuarioContaSistemaRealizouApelido varchar(300) COLLATE Latin1_General_CI_AI NULL,
	IdProduto int NULL,
	StrProdutoNome varchar(300) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_TabelaoInteracaoResumo PRIMARY KEY (IdInteracao)
);
 CREATE NONCLUSTERED INDEX idxDtInclusao ON dbo.TabelaoInteracaoResumoAux (  DtInclusao ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxDtInteracao ON dbo.TabelaoInteracaoResumoAux (  DtInteracao DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxDtInteracaoConclusao ON dbo.TabelaoInteracaoResumoAux (  DtInteracaoConclusao DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxDtInteracaoInclusao ON dbo.TabelaoInteracaoResumoAux (  DtInteracaoInclusao DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdAtendimento ON dbo.TabelaoInteracaoResumoAux (  IdAtendimento ASC  , DtAtualizacaoAuto ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdContaSistema , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdCanal ON dbo.TabelaoInteracaoResumoAux (  IdCanal DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , IdMidia , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdContaSistema2 ON dbo.TabelaoInteracaoResumoAux (  IdContaSistema ASC  , IdAtendimento ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoRealizado , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdInteracao ON dbo.TabelaoInteracaoResumoAux (  IdInteracao ASC  , IdAtendimento ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdContaSistema , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdInteracaoTipo ON dbo.TabelaoInteracaoResumoAux (  IdInteracaoTipo ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdInteracaoWithVersionIntercao ON dbo.TabelaoInteracaoResumoAux (  IdInteracao ASC  , versionIntercao ASC  )  
	 INCLUDE ( IdAtendimento , IdContaSistema , versionAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdMidia ON dbo.TabelaoInteracaoResumoAux (  IdMidia DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdPessoaProspect ON dbo.TabelaoInteracaoResumoAux (  IdPessoaProspect ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxInteracaoTipoValor ON dbo.TabelaoInteracaoResumoAux (  InteracaoTipoValor ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxUsuarioContaSistemaIncluiuId ON dbo.TabelaoInteracaoResumoAux (  UsuarioContaSistemaIncluiuId DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxUsuarioContaSistemaRealizouId ON dbo.TabelaoInteracaoResumoAux (  UsuarioContaSistemaRealizouId DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.sysdiagrams definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.sysdiagrams;

CREATE TABLE SuperCRMDB.dbo.sysdiagrams (
	name sysname COLLATE Latin1_General_CI_AI NOT NULL,
	principal_id int NOT NULL,
	diagram_id int IDENTITY(1,1) NOT NULL,
	version int NULL,
	definition varbinary(MAX) NULL,
	CONSTRAINT PK__sysdiagr__C2B05B6108653E8A PRIMARY KEY (diagram_id),
	CONSTRAINT UK_principal_name UNIQUE (principal_id,name)
);


-- SuperCRMDB.dbo.SuperEntidade definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.SuperEntidade;

CREATE TABLE SuperCRMDB.dbo.SuperEntidade (
	Id int IDENTITY(1,1) NOT NULL,
	SuperEntidadeTipo varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime DEFAULT [dbo].[GetDateCustom]() NOT NULL,
	StrGuid char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	Origem varchar(50) COLLATE Latin1_General_CI_AI DEFAULT 'SUPERCRM' NULL,
	CodigoExterno varchar(100) COLLATE Latin1_General_CI_AI NULL,
	idContaSistema int DEFAULT 1 NOT NULL,
	DtAtualizacaoAuto datetime DEFAULT [dbo].[GetDateCustom]() NULL,
	CONSTRAINT PK_SUPERENTIDADE PRIMARY KEY (Id),
	CONSTRAINT FK_SUPERENT_REFERENCE_CONT9658 FOREIGN KEY (idContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX idxCodigoExterno ON dbo.SuperEntidade (  CodigoExterno ASC  , idContaSistema ASC  )  
	 INCLUDE ( Id , StrGuid , SuperEntidadeTipo ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxDtAtualizacaoAuto ON dbo.SuperEntidade (  DtAtualizacaoAuto DESC  , SuperEntidadeTipo ASC  )  
	 INCLUDE ( Id , idContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxDtInclusao ON dbo.SuperEntidade (  DtInclusao ASC  , Id ASC  )  
	 INCLUDE ( idContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxId ON dbo.SuperEntidade (  Id ASC  , DtInclusao ASC  )  
	 INCLUDE ( DtAtualizacaoAuto , idContaSistema , SuperEntidadeTipo ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdContaSistema1 ON dbo.SuperEntidade (  idContaSistema ASC  , SuperEntidadeTipo ASC  , CodigoExterno ASC  )  
	 INCLUDE ( DtInclusao , Id , StrGuid ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxStrGuid ON dbo.SuperEntidade (  StrGuid ASC  )  
	 INCLUDE ( Id , idContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxSuperEntidadeTipo ON dbo.SuperEntidade (  SuperEntidadeTipo ASC  , idContaSistema ASC  , DtAtualizacaoAuto ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.EnrichPersonLog definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.EnrichPersonLog;

CREATE TABLE SuperCRMDB.dbo.EnrichPersonLog (
	Id int IDENTITY(1,1) NOT NULL,
	IdEnrichPerson int NOT NULL,
	Tipo varchar(80) COLLATE Latin1_General_CI_AI NOT NULL,
	ObjSerializado varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	Obs varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime NOT NULL,
	CONSTRAINT PK_ENRICHPERSONLOG PRIMARY KEY (Id),
	CONSTRAINT FK_ENRICHPE_REFERENCE_ENR123 FOREIGN KEY (IdEnrichPerson) REFERENCES SuperCRMDB.dbo.EnrichPerson(Id) ON DELETE CASCADE
);
 CREATE NONCLUSTERED INDEX idxIdIdEnrichPerson ON dbo.EnrichPersonLog (  IdEnrichPerson ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.BookmarkSuperEntidade definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.BookmarkSuperEntidade;

CREATE TABLE SuperCRMDB.dbo.BookmarkSuperEntidade (
	IdBookmark int NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	IdSuperEntidade int NOT NULL,
	CONSTRAINT PK_BOOKMARKSUPERENTIDADE PRIMARY KEY (IdBookmark,IdSuperEntidade,IdUsuarioContaSistema),
	CONSTRAINT FK_BOOKMARK_REFERENCE_BOO458 FOREIGN KEY (IdBookmark) REFERENCES SuperCRMDB.dbo.Bookmark(Id) ON DELETE CASCADE
);
 CREATE NONCLUSTERED INDEX idxIdSuperEntidade ON dbo.BookmarkSuperEntidade (  IdSuperEntidade ASC  , IdUsuarioContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Produto definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Produto;

CREATE TABLE SuperCRMDB.dbo.Produto (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NOT NULL,
	Nome varchar(300) COLLATE Latin1_General_CI_AI NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	UF char(2) COLLATE Latin1_General_CI_AI NULL,
	Codigo int NULL,
	Tipo varchar(50) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime DEFAULT [dbo].[GetDateCustom]() NOT NULL,
	DtAlteracao datetime NULL,
	GUID char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	ValorMedio decimal(18,2) DEFAULT 0 NOT NULL,
	ComissaoMedio decimal(18,2) DEFAULT 0 NOT NULL,
	versao timestamp NOT NULL,
	CONSTRAINT PK_PRODUTO PRIMARY KEY (Id),
	CONSTRAINT FK_PRODUTO_REFERENCE_CONTASIS FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxGUID ON dbo.Produto (  GUID ASC  )  
	 INCLUDE ( Id , IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.Produto (  IdContaSistema ASC  , Status ASC  )  
	 INCLUDE ( Id , Nome ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxNome ON dbo.Produto (  Nome ASC  , IdContaSistema ASC  )  
	 INCLUDE ( Id , Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxVersao ON dbo.Produto (  versao ASC  , Id ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.PerfilUsuario definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PerfilUsuario;

CREATE TABLE SuperCRMDB.dbo.PerfilUsuario (
	id int IDENTITY(1,1) NOT NULL,
	idContaSistema int NOT NULL,
	Nome varchar(100) COLLATE Latin1_General_CI_AI NOT NULL,
	Obs varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	Administrador bit DEFAULT 0 NOT NULL,
	Permissao varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	DtAtulizacao datetime NOT NULL,
	Padrao bit DEFAULT 0 NOT NULL,
	UrlAutoAcessar varchar(1000) COLLATE Latin1_General_CI_AI NULL,
	Guid char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	versao timestamp NOT NULL,
	CONSTRAINT PK_PERFILUSUARIO PRIMARY KEY (id),
	CONSTRAINT FK_PERFILUS_REFERENCE_CONTASIS FOREIGN KEY (idContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX idx1 ON dbo.PerfilUsuario (  idContaSistema ASC  , Padrao ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.InteracaoTipo definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.InteracaoTipo;

CREATE TABLE SuperCRMDB.dbo.InteracaoTipo (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NOT NULL,
	Valor varchar(200) COLLATE Latin1_General_CI_AI NOT NULL,
	ValorAbreviado varchar(10) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	Mostrar bit DEFAULT 1 NOT NULL,
	Sistema bit DEFAULT 0 NOT NULL,
	Tipo varchar(45) COLLATE Latin1_General_CI_AI NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	CONSTRAINT PK_INTERACAOTIPO PRIMARY KEY (Id),
	CONSTRAINT FK_VISITATI_REFERENCE_CON0054 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id) ON DELETE CASCADE ON UPDATE CASCADE
);
 CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.InteracaoTipo (  IdContaSistema ASC  , Status ASC  )  
	 INCLUDE ( Id , Mostrar , Sistema , Tipo , Valor , ValorAbreviado ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxTipo ON dbo.InteracaoTipo (  Tipo ASC  , IdContaSistema ASC  )  
	 INCLUDE ( Id , Status , Valor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxUnique ON dbo.InteracaoTipo (  IdGuid ASC  )  
	 INCLUDE ( Id , IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX nci_wi_InteracaoTipo_A54BC60B73E134F22BD0880473958C83 ON dbo.InteracaoTipo (  Tipo ASC  )  
	 INCLUDE ( Valor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.PessoaTelefone definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PessoaTelefone;

CREATE TABLE SuperCRMDB.dbo.PessoaTelefone (
	Id int IDENTITY(1,1) NOT NULL,
	IdPessoa int NOT NULL,
	Tipo char(4) COLLATE Latin1_General_CI_AI NOT NULL,
	DDD char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	Telefone varchar(10) COLLATE Latin1_General_CI_AI NOT NULL,
	Ramal varchar(20) COLLATE Latin1_General_CI_AI NULL,
	Obs varchar(400) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime NOT NULL,
	Preferencial bit DEFAULT 0 NOT NULL,
	PreferencialWhats bit DEFAULT 0 NOT NULL,
	versao timestamp NOT NULL,
	CONSTRAINT PK_PESSOATELEFONE PRIMARY KEY (Id),
	CONSTRAINT FK_PESSOATE_REFERENCE_PESSOA FOREIGN KEY (IdPessoa) REFERENCES SuperCRMDB.dbo.Pessoa(Id)
);
 CREATE NONCLUSTERED INDEX idxIdPessoa ON dbo.PessoaTelefone (  IdPessoa ASC  )  
	 INCLUDE ( DDD , Id , Preferencial , Telefone ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.PessoaFisica definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PessoaFisica;

CREATE TABLE SuperCRMDB.dbo.PessoaFisica (
	IdPessoa int NOT NULL,
	DtNascimento date NULL,
	Sexo char(1) COLLATE Latin1_General_CI_AI DEFAULT 'X' NOT NULL,
	Creci varchar(30) COLLATE Latin1_General_CI_AI NULL,
	CPF varchar(11) COLLATE Latin1_General_CI_AI NULL,
	versao timestamp NOT NULL,
	CONSTRAINT PK_PESSOAFISICA PRIMARY KEY (IdPessoa),
	CONSTRAINT FK_PESSOAFI_REFERENCE_PESSOA FOREIGN KEY (IdPessoa) REFERENCES SuperCRMDB.dbo.Pessoa(Id)
);
ALTER TABLE SuperCRMDB.dbo.PessoaFisica WITH NOCHECK ADD CONSTRAINT CKC_SEXO_PESSOAFI CHECK (([Sexo]='M' OR [Sexo]='F' OR [Sexo]='X') AND ([Sexo]='F' OR [Sexo]='M'));


-- SuperCRMDB.dbo.SuperEntidadeAux definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.SuperEntidadeAux;

CREATE TABLE SuperCRMDB.dbo.SuperEntidadeAux (
	Id int NOT NULL,
	IdContaSistema int NOT NULL,
	IdUsuarioContaSistema int NULL,
	DtUltimaAtualizacao datetime NOT NULL,
	Tipo varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	ValorInt int NULL,
	Valor varchar(300) COLLATE Latin1_General_CI_AI NULL,
	ValorDt datetime NULL,
	ObjJson varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	ObjJsonTipo varchar(300) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_SuperEntidadeAux PRIMARY KEY (Id,Tipo),
	CONSTRAINT FK_SUPERENT_REF_SUPERENTAUX FOREIGN KEY (Id) REFERENCES SuperCRMDB.dbo.SuperEntidade(Id) ON DELETE CASCADE
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdTipoUnique ON dbo.SuperEntidadeAux (  Id ASC  , Tipo ASC  )  
	 INCLUDE ( IdContaSistema , Valor , ValorDt , ValorInt ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
ALTER TABLE SuperCRMDB.dbo.SuperEntidadeAux WITH NOCHECK ADD CONSTRAINT CKC_OBJJSON_SuperEntidadeAux CHECK ([SuperEntidadeAux].[ObjJson] IS NULL OR isjson([SuperEntidadeAux].[ObjJson])=(1));


-- SuperCRMDB.dbo.Classificacao definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Classificacao;

CREATE TABLE SuperCRMDB.dbo.Classificacao (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NOT NULL,
	Tipo varchar(150) COLLATE Latin1_General_CI_AI NOT NULL,
	Valor varchar(150) COLLATE Latin1_General_CI_AI NOT NULL,
	Status varchar(2) COLLATE Latin1_General_CI_AI NOT NULL,
	Ordem int DEFAULT 0 NOT NULL,
	DtInclusao datetime NOT NULL,
	Padrao bit DEFAULT 0 NOT NULL,
	Valor2 varchar(150) COLLATE Latin1_General_CI_AI NULL,
	Mostrar bit DEFAULT 1 NOT NULL,
	Acao varchar(150) COLLATE Latin1_General_CI_AI DEFAULT 'PADRAO' NOT NULL,
	PadraoPerda bit DEFAULT 0 NOT NULL,
	PadraoGanho bit DEFAULT 0 NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	ProbabilidadeGanho smallint DEFAULT 1 NOT NULL,
	ObjCamposRequeridos varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	DtAtualizacao datetime NULL,
	versao timestamp NOT NULL,
	CONSTRAINT PK_CLASSIFICACAO PRIMARY KEY (Id),
	CONSTRAINT FK_CLASSIFI_REFERENCE_CONT585 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.Classificacao (  IdContaSistema ASC  , Tipo ASC  , Valor ASC  , Valor2 ASC  )  
	 INCLUDE ( Id , IdGuid , Ordem , Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxUnique ON dbo.Classificacao (  IdGuid ASC  )  
	 INCLUDE ( Id , IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.EnrichPersonQueryParam definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.EnrichPersonQueryParam;

CREATE TABLE SuperCRMDB.dbo.EnrichPersonQueryParam (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdEnrichPerson int NOT NULL,
	Value varchar(1000) COLLATE Latin1_General_CI_AI NOT NULL,
	ValueType varchar(80) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	CONSTRAINT PK_ENRICHPERSONQUERYPARAM PRIMARY KEY (Id),
	CONSTRAINT FK_ENRICHPE_REFERENCE_ENRI145 FOREIGN KEY (IdEnrichPerson) REFERENCES SuperCRMDB.dbo.EnrichPerson(Id) ON DELETE CASCADE
);
 CREATE NONCLUSTERED INDEX idxIdEnrichPerson ON dbo.EnrichPersonQueryParam (  IdEnrichPerson ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.EnrichPersonQueryParam (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxValue ON dbo.EnrichPersonQueryParam (  Value ASC  , ValueType ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.DbLocalidadeCidade definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.DbLocalidadeCidade;

CREATE TABLE SuperCRMDB.dbo.DbLocalidadeCidade (
	Id int IDENTITY(1,1) NOT NULL,
	UF char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	Nome varchar(100) COLLATE Latin1_General_CI_AI NOT NULL,
	NomeAbreviado varchar(50) COLLATE Latin1_General_CI_AI NULL,
	Tipo varchar(255) COLLATE Latin1_General_CI_AI NULL,
	ibge varchar(15) COLLATE Latin1_General_CI_AI NULL,
	populacao varchar(255) COLLATE Latin1_General_CI_AI NULL,
	areakm varchar(20) COLLATE Latin1_General_CI_AI NULL,
	densidade varchar(255) COLLATE Latin1_General_CI_AI NULL,
	entilico varchar(255) COLLATE Latin1_General_CI_AI NULL,
	capital varchar(255) COLLATE Latin1_General_CI_AI NULL,
	distancia_capital varchar(255) COLLATE Latin1_General_CI_AI NULL,
	tempo_percurso varchar(255) COLLATE Latin1_General_CI_AI NULL,
	latitude varchar(255) COLLATE Latin1_General_CI_AI NULL,
	longitude varchar(255) COLLATE Latin1_General_CI_AI NULL,
	DDD char(2) COLLATE Latin1_General_CI_AI NULL,
	cidade_id_new int NULL,
	CONSTRAINT PK_X_CIDADE PRIMARY KEY (Id),
	CONSTRAINT FK42 FOREIGN KEY (UF) REFERENCES SuperCRMDB.dbo.DbLocalidadeUF(Sigla)
);
 CREATE NONCLUSTERED INDEX idx1 ON dbo.DbLocalidadeCidade (  UF ASC  , Nome ASC  , NomeAbreviado ASC  )  
	 INCLUDE ( Id , Tipo ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2 ON dbo.DbLocalidadeCidade (  UF ASC  , NomeAbreviado ASC  , Nome ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx3 ON dbo.DbLocalidadeCidade (  NomeAbreviado ASC  , Nome ASC  , UF ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx4 ON dbo.DbLocalidadeCidade (  NomeAbreviado ASC  , UF ASC  , Nome ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx5 ON dbo.DbLocalidadeCidade (  Nome ASC  , NomeAbreviado ASC  , UF ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx6 ON dbo.DbLocalidadeCidade (  Nome ASC  , UF ASC  , NomeAbreviado ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Canal definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Canal;

CREATE TABLE SuperCRMDB.dbo.Canal (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NOT NULL,
	Tipo varchar(20) COLLATE Latin1_General_CI_AI NOT NULL,
	Nome varchar(100) COLLATE Latin1_General_CI_AI NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	MensagemAutomatica varchar(1500) COLLATE Latin1_General_CI_AI NULL,
	NumeroMaxAtendimentoSimultaneo int DEFAULT -1 NOT NULL,
	TempoMaxInicioAtendimento int DEFAULT 999 NOT NULL,
	TipoTempoMaxInicioAtendimento varchar(15) COLLATE Latin1_General_CI_AI NOT NULL,
	Meio varchar(20) COLLATE Latin1_General_CI_AI DEFAULT 'OUTROS' NOT NULL,
	HabilitarPrevisaoDeMensagem bit DEFAULT 0 NOT NULL,
	GUID char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	DtInclusao datetime DEFAULT [dbo].[GetDateCustom]() NOT NULL,
	TimeExpurgoChat time NULL,
	DtUltimoExpurgoChatExecutado datetime NULL,
	DtProximoExpurgoChat datetime NULL,
	IdCanalTransbordo int NULL,
	versao timestamp NOT NULL,
	CONSTRAINT PK_CANAL PRIMARY KEY (Id),
	CONSTRAINT FK_CANAL_REFERENCE_CANA456 FOREIGN KEY (IdCanalTransbordo) REFERENCES SuperCRMDB.dbo.Canal(Id),
	CONSTRAINT FK_CANAL_REFERENCE_CONTASIS FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.Canal (  GUID ASC  )  
	 INCLUDE ( Id , IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.Canal (  IdContaSistema ASC  , Tipo ASC  , Status ASC  )  
	 INCLUDE ( Id , NumeroMaxAtendimentoSimultaneo ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxTipo ON dbo.Canal (  Tipo ASC  , Status ASC  , DtProximoExpurgoChat ASC  )  
	 INCLUDE ( Id , IdContaSistema , Nome , TimeExpurgoChat ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX nci_wi_Canal_0DA118E70FA700A968F640AC564F304F ON dbo.Canal (  Tipo ASC  )  
	 INCLUDE ( DtInclusao , DtProximoExpurgoChat , DtUltimoExpurgoChatExecutado , GUID , HabilitarPrevisaoDeMensagem , IdCanalTransbordo , IdContaSistema , Meio , MensagemAutomatica , Nome , NumeroMaxAtendimentoSimultaneo , Status , TempoMaxInicioAtendimento , TimeExpurgoChat , TipoTempoMaxInicioAtendimento , versao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Motivacao definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Motivacao;

CREATE TABLE SuperCRMDB.dbo.Motivacao (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NOT NULL,
	Descricao varchar(250) COLLATE Latin1_General_CI_AI NOT NULL,
	Tipo varchar(100) COLLATE Latin1_General_CI_AI NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	CONSTRAINT PK_MOTIVACAO PRIMARY KEY (Id),
	CONSTRAINT FK_MOTIVACA_REFERENCE_CO4589 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX IDXCONTASISTEMA ON dbo.Motivacao (  IdContaSistema ASC  , IdGuid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.Motivacao (  IdGuid ASC  )  
	 INCLUDE ( IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.MidiaTipo definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.MidiaTipo;

CREATE TABLE SuperCRMDB.dbo.MidiaTipo (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NULL,
	Valor varchar(300) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	CONSTRAINT PK_MIDIATIPO PRIMARY KEY (Id),
	CONSTRAINT FK_MIDIATIP_REFERENCE_CON2j22 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxUnique ON dbo.MidiaTipo (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.CampanhaMarketing definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.CampanhaMarketing;

CREATE TABLE SuperCRMDB.dbo.CampanhaMarketing (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NOT NULL,
	Nome varchar(500) COLLATE Latin1_General_CI_AI NULL,
	Obs varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	AutoInclusao bit DEFAULT 0 NOT NULL,
	DtInclusao datetime NOT NULL,
	CONSTRAINT PK_CAMPANHAMARKETING PRIMARY KEY (Id),
	CONSTRAINT FK_CAMPANHA_REFERENCE_CONTASI5 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.CampanhaMarketing (  IdContaSistema ASC  , Nome ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.InteracaoTipoAtorPartida definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.InteracaoTipoAtorPartida;

CREATE TABLE SuperCRMDB.dbo.InteracaoTipoAtorPartida (
	Id int IDENTITY(1,1) NOT NULL,
	IdInteracaoTipo int NOT NULL,
	InteracaoAtorPartida varchar(30) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_INTERACAOTIPOATORPARTIDA PRIMARY KEY (Id),
	CONSTRAINT FK_INTERACA_REFERENCE_INTER785 FOREIGN KEY (IdInteracaoTipo) REFERENCES SuperCRMDB.dbo.InteracaoTipo(Id) ON DELETE CASCADE ON UPDATE CASCADE
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.InteracaoTipoAtorPartida (  IdInteracaoTipo ASC  , InteracaoAtorPartida ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.GrupoPecaMarketing definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.GrupoPecaMarketing;

CREATE TABLE SuperCRMDB.dbo.GrupoPecaMarketing (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NOT NULL,
	Nome varchar(500) COLLATE Latin1_General_CI_AI NULL,
	Obs varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	AutoInclusao bit DEFAULT 0 NOT NULL,
	DtInclusao datetime NOT NULL,
	CONSTRAINT PK_GRUPOPECAMARKETING PRIMARY KEY (Id),
	CONSTRAINT FK_GRUPOPEC_REFERENCE_CONTASIS FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.GrupoPecaMarketing (  IdContaSistema ASC  , Nome ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.CanalInteracaoTipo definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.CanalInteracaoTipo;

CREATE TABLE SuperCRMDB.dbo.CanalInteracaoTipo (
	Id int IDENTITY(1,1) NOT NULL,
	IdCanal int NOT NULL,
	IdInteracaoTipo int NOT NULL,
	DtInclusao datetime NOT NULL,
	CONSTRAINT PK_CANALINTERACAOTIPO PRIMARY KEY (Id),
	CONSTRAINT FK_CANALINT_REFERENCE_C784 FOREIGN KEY (IdCanal) REFERENCES SuperCRMDB.dbo.Canal(Id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT FK_CANALINT_REFERENCE_INT457 FOREIGN KEY (IdInteracaoTipo) REFERENCES SuperCRMDB.dbo.InteracaoTipo(Id) ON DELETE CASCADE ON UPDATE CASCADE
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.CanalInteracaoTipo (  IdCanal ASC  , IdInteracaoTipo ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.EnrichPersonEnrichPersonDataSource definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.EnrichPersonEnrichPersonDataSource;

CREATE TABLE SuperCRMDB.dbo.EnrichPersonEnrichPersonDataSource (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid varchar(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdEnrichPersonDataSource int NOT NULL,
	IdEnrichPerson int NOT NULL,
	DtInclusao datetime NOT NULL,
	CONSTRAINT PK_ENRICHPERSONENRICHPERSONDAT PRIMARY KEY (Id),
	CONSTRAINT FK_ENRICHPE_REFERENCE_ENR455 FOREIGN KEY (IdEnrichPerson) REFERENCES SuperCRMDB.dbo.EnrichPerson(Id) ON DELETE CASCADE,
	CONSTRAINT FK_ENRICHPE_REFERENCE_ENRI487 FOREIGN KEY (IdEnrichPersonDataSource) REFERENCES SuperCRMDB.dbo.EnrichPersonDataSource(Id)
);
 CREATE NONCLUSTERED INDEX idxIdEnrichPerson ON dbo.EnrichPersonEnrichPersonDataSource (  IdEnrichPerson ASC  , IdEnrichPersonDataSource ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.EnrichPersonEnrichPersonDataSource (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.FichaPesquisa definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.FichaPesquisa;

CREATE TABLE SuperCRMDB.dbo.FichaPesquisa (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NOT NULL,
	Nome varchar(200) COLLATE Latin1_General_CI_AI NOT NULL,
	Descricao varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	AutoNumerarPerguntas bit DEFAULT 1 NOT NULL,
	idGuid char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	CONSTRAINT PK_FICHAPESQUISA PRIMARY KEY (Id),
	CONSTRAINT FK_FICHAPES_REFERENCE_CONTASIS FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX IDXIDCONTASISTEMA ON dbo.FichaPesquisa (  IdContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.ContaSistemaHost definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.ContaSistemaHost;

CREATE TABLE SuperCRMDB.dbo.ContaSistemaHost (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NOT NULL,
	Host varchar(1000) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	Padrao bit DEFAULT 0 NOT NULL,
	Tipo varchar(50) COLLATE Latin1_General_CI_AI DEFAULT 'SISTEMA' NOT NULL,
	CONSTRAINT PK_CONTASISTEMAHOST PRIMARY KEY (Id),
	CONSTRAINT FK_CONTASIS_REFERENCE_CON45SIS FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX idxContaSistema ON dbo.ContaSistemaHost (  IdContaSistema ASC  , Host ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxUnique ON dbo.ContaSistemaHost (  Host ASC  )  
	 WHERE  ([TIPO]<>'APP')
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX nci_wi_ContaSistemaHost_175581158A671475DDF5DF37839F3ABF ON dbo.ContaSistemaHost (  Host ASC  , IdContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.FichaPesquisaTipo definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.FichaPesquisaTipo;

CREATE TABLE SuperCRMDB.dbo.FichaPesquisaTipo (
	Id int IDENTITY(1,1) NOT NULL,
	IdFichaPesquisa int NOT NULL,
	Tipo varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	CONSTRAINT PK_FICHAPESQUISATIPO PRIMARY KEY (Id),
	CONSTRAINT FK_FICHAPES_REFERENCE_FICHAP589 FOREIGN KEY (IdFichaPesquisa) REFERENCES SuperCRMDB.dbo.FichaPesquisa(Id) ON DELETE CASCADE
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.FichaPesquisaTipo (  IdFichaPesquisa ASC  , Tipo ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.ModuloSistemaContaSistema definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.ModuloSistemaContaSistema;

CREATE TABLE SuperCRMDB.dbo.ModuloSistemaContaSistema (
	Id int IDENTITY(1,1) NOT NULL,
	IdModuloSistema int NOT NULL,
	IdContaSistema int NOT NULL,
	DtInclusao datetime NOT NULL,
	CONSTRAINT PK_MODULOSISTEMACONTASISTEMA PRIMARY KEY (Id),
	CONSTRAINT FK_MODULOSI_REFERENCE_CONTA454 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id),
	CONSTRAINT FK_MODULOSI_REFERENCE_MODULOSI FOREIGN KEY (IdModuloSistema) REFERENCES SuperCRMDB.dbo.ModuloSistema(Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.ModuloSistemaContaSistema (  IdContaSistema ASC  , IdModuloSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdModuloSistema ON dbo.ModuloSistemaContaSistema (  IdModuloSistema ASC  , IdContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.DbLocalidadeCEPFaixaCidade definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.DbLocalidadeCEPFaixaCidade;

CREATE TABLE SuperCRMDB.dbo.DbLocalidadeCEPFaixaCidade (
	ID int IDENTITY(1,1) NOT NULL,
	IdCidade int NOT NULL,
	FaixaCEPInicio int NOT NULL,
	FaixaCEPFim int NULL,
	CONSTRAINT PK_DbLocalidadeCEPFaixaCidade PRIMARY KEY (ID),
	CONSTRAINT FK81 FOREIGN KEY (IdCidade) REFERENCES SuperCRMDB.dbo.DbLocalidadeCidade(Id) ON DELETE CASCADE
);


-- SuperCRMDB.dbo.PessoaProfissao definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PessoaProfissao;

CREATE TABLE SuperCRMDB.dbo.PessoaProfissao (
	Id int IDENTITY(1,1) NOT NULL,
	StrGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdContaSistema int NULL,
	Nome varchar(250) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	CONSTRAINT PK_PESSOAPROFISSAO PRIMARY KEY (Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_CON789 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id) ON DELETE CASCADE
);
 CREATE  UNIQUE NONCLUSTERED INDEX idx1 ON dbo.PessoaProfissao (  IdContaSistema ASC  , Nome ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.RegraFidelizacao definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.RegraFidelizacao;

CREATE TABLE SuperCRMDB.dbo.RegraFidelizacao (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdContaSistema int NOT NULL,
	DtCriacao datetime NOT NULL,
	Nome varchar(300) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_REGRAFIDELIZACAO PRIMARY KEY (Id),
	CONSTRAINT FK_REGRAFID_REFERENCE_CONT256 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.RegraFidelizacao (  IdContaSistema ASC  )  
	 INCLUDE ( Id , IdGuid ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.RegraFidelizacao (  IdGuid ASC  , IdContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Transportadora definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Transportadora;

CREATE TABLE SuperCRMDB.dbo.Transportadora (
	Id int IDENTITY(1,1) NOT NULL,
	Nome varchar(500) COLLATE Latin1_General_CI_AI NOT NULL,
	Tipo varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	TipoMensagem varchar(15) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	ObjTipo varchar(500) COLLATE Latin1_General_CI_AI NOT NULL,
	Obj varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	idTransportadoraPai int NULL,
	HerancaTipo varchar(10) COLLATE Latin1_General_CI_AI NOT NULL,
	CodigoExternoIdentificador varchar(300) COLLATE Latin1_General_CI_AI NULL,
	CodigoExterno varchar(300) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_TRANSPORTADORA PRIMARY KEY (Id),
	CONSTRAINT FK_TRANSPOR_REFERENCE_TRAN458 FOREIGN KEY (idTransportadoraPai) REFERENCES SuperCRMDB.dbo.Transportadora(Id)
);
 CREATE NONCLUSTERED INDEX idxCodigoExterno ON dbo.Transportadora (  CodigoExterno ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxCodigoExternoIdentificador ON dbo.Transportadora (  CodigoExternoIdentificador ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.Transportadora (  IdGuid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdTransportadoraPai ON dbo.Transportadora (  idTransportadoraPai ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.OportunidadeNegocioTipo definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.OportunidadeNegocioTipo;

CREATE TABLE SuperCRMDB.dbo.OportunidadeNegocioTipo (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NOT NULL,
	Nome varchar(200) COLLATE Latin1_General_CI_AI NOT NULL,
	Descricao varchar(100) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime DEFAULT [dbo].[GetDateCustom]() NOT NULL,
	Tipo varchar(200) COLLATE Latin1_General_CI_AI DEFAULT 'VENDA' NULL,
	CONSTRAINT PK_OPORTUNIDADENEGOCIOTIPO PRIMARY KEY (Id),
	CONSTRAINT FK_OPORTUNI_REFERENCE_CONW785 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX IDXCONTASISTEMA ON dbo.OportunidadeNegocioTipo (  IdContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.OportunidadeNegocioTipo (  Nome ASC  , IdContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Telefonia definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Telefonia;

CREATE TABLE SuperCRMDB.dbo.Telefonia (
	IdTransportadora int NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_TELEFONIA PRIMARY KEY (IdTransportadora),
	CONSTRAINT FK_TELEFONI_REFERENCE_TRANS986 FOREIGN KEY (IdTransportadora) REFERENCES SuperCRMDB.dbo.Transportadora(Id) ON DELETE CASCADE
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxGuidUnique ON dbo.Telefonia (  IdGuid ASC  )  
	 INCLUDE ( IdTransportadora ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.TransportadoraContaSistema definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.TransportadoraContaSistema;

CREATE TABLE SuperCRMDB.dbo.TransportadoraContaSistema (
	Id int IDENTITY(1,1) NOT NULL,
	IdTransportadora int NOT NULL,
	IdContaSistema int NOT NULL,
	DtInclusao datetime NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_TRANSPORTADORACONTASISTEMA PRIMARY KEY (Id),
	CONSTRAINT FK_TRANSPOR_REFERENCE_CON369 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id),
	CONSTRAINT FK_TRANSPOR_REFERENCE_TRANSPOR FOREIGN KEY (IdTransportadora) REFERENCES SuperCRMDB.dbo.Transportadora(Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdContaSistemaTransportadoraUnique ON dbo.TransportadoraContaSistema (  IdContaSistema ASC  , IdTransportadora ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.TransportadoraContaSistema (  IdGuid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.DashboardCard definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.DashboardCard;

CREATE TABLE SuperCRMDB.dbo.DashboardCard (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdCard int NOT NULL,
	IdDashboard int NOT NULL,
	DtInclusao datetime NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	ObjTipo varchar(400) COLLATE Latin1_General_CI_AI NOT NULL,
	ObjJson varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_DASHBOARDCARD PRIMARY KEY (Id),
	CONSTRAINT FK_DASHBOAR_REFE_CARD FOREIGN KEY (IdCard) REFERENCES SuperCRMDB.dbo.Card(Id) ON DELETE CASCADE,
	CONSTRAINT FK_DASHBOAR_REF_DASHBOAR2 FOREIGN KEY (IdDashboard) REFERENCES SuperCRMDB.dbo.Dashboard(Id) ON DELETE CASCADE
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.DashboardCard (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxUnique ON dbo.DashboardCard (  IdCard ASC  , IdDashboard ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.ProdutoSub definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.ProdutoSub;

CREATE TABLE SuperCRMDB.dbo.ProdutoSub (
	Id int IDENTITY(1,1) NOT NULL,
	IdProduto int NOT NULL,
	Nome varchar(300) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	idGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_PRODUTOSUB PRIMARY KEY (Id),
	CONSTRAINT FK_PRODUTOS_REFERENCE_PR458 FOREIGN KEY (IdProduto) REFERENCES SuperCRMDB.dbo.Produto(Id) ON DELETE CASCADE ON UPDATE CASCADE
);
 CREATE NONCLUSTERED INDEX IDXIDPRODUTO ON dbo.ProdutoSub (  IdProduto ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.ProdutoSub (  idGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.AcaoEventoTipo definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.AcaoEventoTipo;

CREATE TABLE SuperCRMDB.dbo.AcaoEventoTipo (
	Id int IDENTITY(1,1) NOT NULL,
	EventoTipo varchar(100) COLLATE Latin1_General_CI_AI NOT NULL,
	IdAcao int NOT NULL,
	HrValidadeProcessamentoInicio time NULL,
	HrValidadeProcessamentoFim time NULL,
	AutoExecutavel bit DEFAULT 0 NOT NULL,
	CONSTRAINT PK_ACAOEVENTOTIPO PRIMARY KEY (Id),
	CONSTRAINT FK_ACAOTIPO_REFERENCE_AC966 FOREIGN KEY (IdAcao) REFERENCES SuperCRMDB.dbo.Acao(Id) ON DELETE CASCADE,
	CONSTRAINT FK_ACAOTIPO_REFERENCE_TIPO896 FOREIGN KEY (EventoTipo) REFERENCES SuperCRMDB.dbo.EventoTipo(Tipo) ON DELETE CASCADE ON UPDATE CASCADE
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.AcaoEventoTipo (  EventoTipo ASC  , IdAcao ASC  )  
	 INCLUDE ( AutoExecutavel ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.ProdutoMarcoTipo definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.ProdutoMarcoTipo;

CREATE TABLE SuperCRMDB.dbo.ProdutoMarcoTipo (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NOT NULL,
	Valor varchar(150) COLLATE Latin1_General_CI_AI NOT NULL,
	idGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_PRODUTOMARCOTIPO PRIMARY KEY (Id),
	CONSTRAINT FK_PRODUTOM_REFERENCE_CON4587 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.ProdutoMarcoTipo (  idGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.DbLocalidadeCEPFaixaUF definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.DbLocalidadeCEPFaixaUF;

CREATE TABLE SuperCRMDB.dbo.DbLocalidadeCEPFaixaUF (
	UF char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	FaixaCEPInicio int NOT NULL,
	FaixaCEPFim int NOT NULL,
	Regiao varchar(100) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_X_CEPFAIXAUF PRIMARY KEY (UF,FaixaCEPInicio,FaixaCEPFim),
	CONSTRAINT FK80 FOREIGN KEY (UF) REFERENCES SuperCRMDB.dbo.DbLocalidadeUF(Sigla)
);


-- SuperCRMDB.dbo.Perfil definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Perfil;

CREATE TABLE SuperCRMDB.dbo.Perfil (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NOT NULL,
	Nome varchar(30) COLLATE Latin1_General_CI_AI NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_PERFIL PRIMARY KEY (Id),
	CONSTRAINT FK_PERFIL_REFERENCE_CONTASIS FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id)
);


-- SuperCRMDB.dbo.AcaoVariavel definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.AcaoVariavel;

CREATE TABLE SuperCRMDB.dbo.AcaoVariavel (
	Id int IDENTITY(1,1) NOT NULL,
	IdAcao int NOT NULL,
	Nome varchar(1000) COLLATE Latin1_General_CI_AI NOT NULL,
	Descricao varchar(1000) COLLATE Latin1_General_CI_AI NOT NULL,
	Tipo varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	QtdMax int DEFAULT 0 NOT NULL,
	Obrigatorio bit DEFAULT 0 NOT NULL,
	CodigoVariavel varchar(200) COLLATE Latin1_General_CI_AI NOT NULL,
	Ativo bit DEFAULT 1 NOT NULL,
	CONSTRAINT PK_ACAOVARIAVEL PRIMARY KEY (Id),
	CONSTRAINT FK_ACAOVARI_REFERENCE_ACAO458 FOREIGN KEY (IdAcao) REFERENCES SuperCRMDB.dbo.Acao(Id) ON DELETE CASCADE
);


-- SuperCRMDB.dbo.PessoaJuridica definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PessoaJuridica;

CREATE TABLE SuperCRMDB.dbo.PessoaJuridica (
	IdPessoa int NOT NULL,
	NomeFantasia varchar(200) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_PESSOAJURIDICA PRIMARY KEY (IdPessoa),
	CONSTRAINT FK_PESSOAJU_REFERENCE_PESSOA FOREIGN KEY (IdPessoa) REFERENCES SuperCRMDB.dbo.Pessoa(Id)
);


-- SuperCRMDB.dbo.Usuario definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Usuario;

CREATE TABLE SuperCRMDB.dbo.Usuario (
	IdPessoa int NOT NULL,
	GuidUsuarioCorrex char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	DtAtualizacao datetime NOT NULL,
	DtInclusao datetime NOT NULL,
	SysAdm bit DEFAULT 0 NOT NULL,
	SysAdmPermissao varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	versao timestamp NOT NULL,
	CONSTRAINT PK_USUARIO PRIMARY KEY (IdPessoa),
	CONSTRAINT FK_USUARIO_REFERENCE_PESSOAFI FOREIGN KEY (IdPessoa) REFERENCES SuperCRMDB.dbo.PessoaFisica(IdPessoa)
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDXGUIDUSUARIOCORREX ON dbo.Usuario (  GuidUsuarioCorrex ASC  , IdPessoa ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.DbLocalidadeBairro definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.DbLocalidadeBairro;

CREATE TABLE SuperCRMDB.dbo.DbLocalidadeBairro (
	Id int IDENTITY(1,1) NOT NULL,
	IdCidade int NOT NULL,
	NomeOficial varchar(80) COLLATE Latin1_General_CI_AI NOT NULL,
	Nome varchar(80) COLLATE Latin1_General_CI_AI NOT NULL,
	NomeAbreviado varchar(80) COLLATE Latin1_General_CI_AI NULL,
	latitude varchar(255) COLLATE Latin1_General_CI_AI NULL,
	longitude varchar(255) COLLATE Latin1_General_CI_AI NULL,
	bairro_id_new int NULL,
	cidade_id_new int NULL,
	CONSTRAINT PK_X_BAIRRO PRIMARY KEY (Id),
	CONSTRAINT FK5 FOREIGN KEY (IdCidade) REFERENCES SuperCRMDB.dbo.DbLocalidadeCidade(Id) ON DELETE CASCADE
);
 CREATE NONCLUSTERED INDEX idx1 ON dbo.DbLocalidadeBairro (  IdCidade ASC  )  
	 INCLUDE ( Id , Nome , NomeAbreviado , NomeOficial ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2 ON dbo.DbLocalidadeBairro (  IdCidade ASC  , NomeOficial ASC  , Nome ASC  , NomeAbreviado ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx3 ON dbo.DbLocalidadeBairro (  NomeOficial ASC  , IdCidade ASC  )  
	 INCLUDE ( Id , Nome , NomeAbreviado ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx4 ON dbo.DbLocalidadeBairro (  Nome ASC  , IdCidade ASC  )  
	 INCLUDE ( Id , NomeAbreviado , NomeOficial ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx5 ON dbo.DbLocalidadeBairro (  NomeAbreviado ASC  , IdCidade ASC  )  
	 INCLUDE ( Id , Nome , NomeOficial ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Campanha definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Campanha;

CREATE TABLE SuperCRMDB.dbo.Campanha (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NOT NULL,
	Nome varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	NumeroMaxAtendimentoSimultaneo int DEFAULT 999 NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	GUID char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	HoraInicioFuncionamentoRoleta time NULL,
	HoraFinalFuncionamentoRoleta time NULL,
	IdRegraFidelizacao int NULL,
	versao timestamp NOT NULL,
	CONSTRAINT PK_CAMPANHA PRIMARY KEY (Id),
	CONSTRAINT FK_CAMPANHA_REFERENCE_CONTASIS FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id),
	CONSTRAINT FK_CAMPANHA_REFERENCE_REGR458 FOREIGN KEY (IdRegraFidelizacao) REFERENCES SuperCRMDB.dbo.RegraFidelizacao(Id) ON DELETE SET NULL
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.Campanha (  GUID ASC  )  
	 INCLUDE ( IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.Campanha (  IdContaSistema ASC  , Status ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdRegraFidelizacao ON dbo.Campanha (  IdRegraFidelizacao ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxVersao ON dbo.Campanha (  versao ASC  , Id ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Plantao definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Plantao;

CREATE TABLE SuperCRMDB.dbo.Plantao (
	Id int IDENTITY(1,1) NOT NULL,
	IdCampanha int NOT NULL,
	Nome varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInicioValidade datetime NOT NULL,
	DtFimValidade datetime NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_PLANTAO PRIMARY KEY (Id),
	CONSTRAINT FK_PLANTAO_REFERENCE_CAMPANHA FOREIGN KEY (IdCampanha) REFERENCES SuperCRMDB.dbo.Campanha(Id)
);
 CREATE NONCLUSTERED INDEX idxDtInicioValidade ON dbo.Plantao (  DtInicioValidade ASC  , DtFimValidade ASC  , Status ASC  )  
	 INCLUDE ( Id , IdCampanha ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdCampanha ON dbo.Plantao (  IdCampanha ASC  , DtInicioValidade ASC  , DtFimValidade ASC  , Status ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxStatus ON dbo.Plantao (  Status ASC  , DtFimValidade ASC  )  
	 INCLUDE ( DtInicioValidade , IdCampanha ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Pergunta definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Pergunta;

CREATE TABLE SuperCRMDB.dbo.Pergunta (
	Id int IDENTITY(1,1) NOT NULL,
	IdFichaPesquisa int NOT NULL,
	Descricao varchar(8000) COLLATE Latin1_General_CI_AI NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	Tipo varchar(10) COLLATE Latin1_General_CI_AI NOT NULL,
	TipoGrafico varchar(20) COLLATE Latin1_General_CI_AI NULL,
	Obrigatorio bit DEFAULT 1 NOT NULL,
	DtInclusao datetime NOT NULL,
	idGuid char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	CONSTRAINT PK_PERGUNTA PRIMARY KEY (Id),
	CONSTRAINT FK_PERGUNTA_REFERENCE_FICHAPES FOREIGN KEY (IdFichaPesquisa) REFERENCES SuperCRMDB.dbo.FichaPesquisa(Id)
);
 CREATE NONCLUSTERED INDEX idx1 ON dbo.Pergunta (  IdFichaPesquisa ASC  , Obrigatorio ASC  , Status ASC  )  
	 INCLUDE ( Id , Tipo ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.CampanhaFichaPesquisa definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.CampanhaFichaPesquisa;

CREATE TABLE SuperCRMDB.dbo.CampanhaFichaPesquisa (
	Id int IDENTITY(1,1) NOT NULL,
	IdCampanha int NOT NULL,
	IdFichaPesquisa int NOT NULL,
	FichaPesquisaTipo varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	CONSTRAINT PK_CAMPANHAFICHAPESQUISA PRIMARY KEY (Id),
	CONSTRAINT FK_CAMPANHA_REFERENCE_CAMPA500 FOREIGN KEY (IdCampanha) REFERENCES SuperCRMDB.dbo.Campanha(Id) ON DELETE CASCADE,
	CONSTRAINT FK_CAMPANHA_REFERENCE_FICHA148 FOREIGN KEY (IdFichaPesquisa) REFERENCES SuperCRMDB.dbo.FichaPesquisa(Id) ON DELETE CASCADE
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.CampanhaFichaPesquisa (  IdCampanha ASC  , FichaPesquisaTipo ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx1 ON dbo.CampanhaFichaPesquisa (  IdCampanha ASC  , IdFichaPesquisa ASC  , FichaPesquisaTipo ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.CampanhaAdministrador definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.CampanhaAdministrador;

CREATE TABLE SuperCRMDB.dbo.CampanhaAdministrador (
	Id int IDENTITY(1,1) NOT NULL,
	IdCampanha int NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	DtInclusao datetime NOT NULL,
	CONSTRAINT PK_CAMPANHAADMINISTRADOR PRIMARY KEY (Id),
	CONSTRAINT FK_CAMPANHA_REFERENCE_CAMP333 FOREIGN KEY (IdCampanha) REFERENCES SuperCRMDB.dbo.Campanha(Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX idx1 ON dbo.CampanhaAdministrador (  IdCampanha ASC  , IdUsuarioContaSistema ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idx2 ON dbo.CampanhaAdministrador (  IdUsuarioContaSistema ASC  , IdCampanha ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.ContaSistemaTelefoniaConf definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.ContaSistemaTelefoniaConf;

CREATE TABLE SuperCRMDB.dbo.ContaSistemaTelefoniaConf (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdContaSistema int NOT NULL,
	IdTransportadoraContaSistema int NULL,
	Tipo varchar(15) COLLATE Latin1_General_CI_AI NOT NULL,
	ObjTipo varchar(500) COLLATE Latin1_General_CI_AI NOT NULL,
	Obj varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	Ativo bit NOT NULL,
	DtInclusao datetime NOT NULL,
	DtModificacao datetime NOT NULL,
	CONSTRAINT PK_CONTASISTEMATELEFONIACONF PRIMARY KEY (Id),
	CONSTRAINT FK_CONTASIS_REFERENCE_CONT258 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id) ON DELETE CASCADE,
	CONSTRAINT FK_CONTASIS_REFERENCE_TRAN778 FOREIGN KEY (IdTransportadoraContaSistema) REFERENCES SuperCRMDB.dbo.TransportadoraContaSistema(Id) ON DELETE SET NULL
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxContaSistemaTipoUnique ON dbo.ContaSistemaTelefoniaConf (  IdContaSistema ASC  , Tipo ASC  )  
	 INCLUDE ( Ativo , IdTransportadoraContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxGuidUnique ON dbo.ContaSistemaTelefoniaConf (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.ProdutoMarco definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.ProdutoMarco;

CREATE TABLE SuperCRMDB.dbo.ProdutoMarco (
	Id int IDENTITY(1,1) NOT NULL,
	IdProduto int NOT NULL,
	IdProdutoMarcoTipo int NOT NULL,
	DtInicio datetime NOT NULL,
	DtFim datetime NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	Valor varchar(150) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	idGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_PRODUTOMARCO PRIMARY KEY (Id),
	CONSTRAINT FK_PRODUTOM_REFERENCE_PR7858 FOREIGN KEY (IdProduto) REFERENCES SuperCRMDB.dbo.Produto(Id),
	CONSTRAINT FK_PRODUTOM_REFERENCE_PRO4587 FOREIGN KEY (IdProdutoMarcoTipo) REFERENCES SuperCRMDB.dbo.ProdutoMarcoTipo(Id)
);
 CREATE NONCLUSTERED INDEX IDX1 ON dbo.ProdutoMarco (  IdProdutoMarcoTipo ASC  , DtInicio ASC  , DtFim ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.ProdutoMarco (  idGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.AutorizacaoIP definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.AutorizacaoIP;

CREATE TABLE SuperCRMDB.dbo.AutorizacaoIP (
	Id int IDENTITY(1,1) NOT NULL,
	IdPessoa int NOT NULL,
	IP varchar(20) COLLATE Latin1_General_CI_AI NOT NULL,
	IPLocalRegistrou varchar(20) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	DtValidade datetime NULL,
	Obs varchar(1000) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_AUTORIZACAOIP PRIMARY KEY (Id),
	CONSTRAINT FK_AUTORIZA_REFERENCE_USU47786 FOREIGN KEY (IdPessoa) REFERENCES SuperCRMDB.dbo.Usuario(IdPessoa)
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDXIP ON dbo.AutorizacaoIP (  IP ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.CampanhaFichaPesquisaPerguntaProdutoSub definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.CampanhaFichaPesquisaPerguntaProdutoSub;

CREATE TABLE SuperCRMDB.dbo.CampanhaFichaPesquisaPerguntaProdutoSub (
	Id int IDENTITY(1,1) NOT NULL,
	IdCampanhaFichaPesquisa int NOT NULL,
	IdPergunta int NOT NULL,
	IdProdutoSub int NOT NULL,
	CONSTRAINT PK_CAMPANHAFICHAPESQUISAPERGUN PRIMARY KEY (Id),
	CONSTRAINT FK_CAMPANHA_REFERENCE_CAM4787 FOREIGN KEY (IdCampanhaFichaPesquisa) REFERENCES SuperCRMDB.dbo.CampanhaFichaPesquisa(Id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT FK_CAMPANHA_REFERENCE_PER4444 FOREIGN KEY (IdPergunta) REFERENCES SuperCRMDB.dbo.Pergunta(Id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT FK_CAMPANHA_REFERENCE_PRO3434 FOREIGN KEY (IdProdutoSub) REFERENCES SuperCRMDB.dbo.ProdutoSub(Id) ON DELETE CASCADE ON UPDATE CASCADE
);
 CREATE NONCLUSTERED INDEX IDX ON dbo.CampanhaFichaPesquisaPerguntaProdutoSub (  IdCampanhaFichaPesquisa ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.CampanhaFichaPesquisaPerguntaProdutoSub (  IdCampanhaFichaPesquisa ASC  , IdProdutoSub ASC  , IdPergunta ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.DbLocalidadeCEPFaixaBairro definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.DbLocalidadeCEPFaixaBairro;

CREATE TABLE SuperCRMDB.dbo.DbLocalidadeCEPFaixaBairro (
	IdBairro int NOT NULL,
	FaixaCEPInicio int NOT NULL,
	FaixaCEPFim int NOT NULL,
	CONSTRAINT PK_X_CEPFAIXABAIRRO PRIMARY KEY (IdBairro,FaixaCEPInicio,FaixaCEPFim),
	CONSTRAINT FK82 FOREIGN KEY (IdBairro) REFERENCES SuperCRMDB.dbo.DbLocalidadeBairro(Id) ON DELETE CASCADE
);


-- SuperCRMDB.dbo.UsuarioContaSistema definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.UsuarioContaSistema;

CREATE TABLE SuperCRMDB.dbo.UsuarioContaSistema (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NOT NULL,
	IdPessoa int NOT NULL,
	idPerfilUsuario int NOT NULL,
	DtInclusao datetime NOT NULL,
	DtAtualizacao datetime NOT NULL,
	QtdAcesso int DEFAULT 0 NOT NULL,
	DtUltimoAcesso datetime NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	GUID char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	DtExpiracao datetime NULL,
	FilaCanalOffLine bit DEFAULT 1 NOT NULL,
	FilaCanalOnLine bit DEFAULT 1 NOT NULL,
	DtUltimaRequisicao datetime NULL,
	FilaCanalTelefone bit DEFAULT 0 NOT NULL,
	AccessToken char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	AccessTokenData datetime NULL,
	DtUltimaRequisicao2 datetime NULL,
	FilaCanalWhatsApp bit DEFAULT 0 NOT NULL,
	versao timestamp NOT NULL,
	CONSTRAINT PK_USUARIOCONTASISTEMA PRIMARY KEY (Id),
	CONSTRAINT FK_USUARIOC_REFERENCE_CONTASIS FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id),
	CONSTRAINT FK_USUARIOC_REFERENCE_PERFILUS FOREIGN KEY (idPerfilUsuario) REFERENCES SuperCRMDB.dbo.PerfilUsuario(id),
	CONSTRAINT FK_USUARIOC_REFERENCE_USUARI0 FOREIGN KEY (IdPessoa) REFERENCES SuperCRMDB.dbo.Usuario(IdPessoa)
);
 CREATE NONCLUSTERED INDEX idx2DtUltimaRequisicao ON dbo.UsuarioContaSistema (  DtUltimaRequisicao DESC  , Id ASC  )  
	 INCLUDE ( IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxDtExpiracao ON dbo.UsuarioContaSistema (  DtExpiracao ASC  , Status ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxGUID ON dbo.UsuarioContaSistema (  GUID ASC  )  
	 INCLUDE ( IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdContaSistema ON dbo.UsuarioContaSistema (  IdContaSistema ASC  , IdPessoa ASC  )  
	 INCLUDE ( DtAtualizacao , DtExpiracao , DtInclusao , DtUltimoAcesso , FilaCanalOffLine , FilaCanalOnLine , GUID , Id , idPerfilUsuario , QtdAcesso , Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdContaSistema2 ON dbo.UsuarioContaSistema (  IdContaSistema ASC  , Status ASC  )  
	 INCLUDE ( AccessToken , AccessTokenData , DtAtualizacao , DtExpiracao , DtInclusao , DtUltimoAcesso , FilaCanalOffLine , FilaCanalOnLine , FilaCanalTelefone , GUID , idPerfilUsuario , IdPessoa , QtdAcesso ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdPessoa ON dbo.UsuarioContaSistema (  IdPessoa ASC  , IdContaSistema ASC  )  
	 INCLUDE ( Id , Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdPessoaUnique ON dbo.UsuarioContaSistema (  IdPessoa ASC  , IdContaSistema ASC  )  
	 INCLUDE ( Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdUnique ON dbo.UsuarioContaSistema (  Id ASC  , IdContaSistema ASC  , Status ASC  )  
	 INCLUDE ( GUID , idPerfilUsuario , IdPessoa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxStatus ON dbo.UsuarioContaSistema (  Status ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtExpiracao , Id , idPerfilUsuario , IdPessoa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxUniqueToken ON dbo.UsuarioContaSistema (  AccessToken ASC  , IdContaSistema ASC  )  
	 INCLUDE ( GUID , Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX nci_wi_UsuarioContaSistema_5A721C9CDBE9E6A1BA58F8BCCF1AC52A ON dbo.UsuarioContaSistema (  FilaCanalOnLine ASC  , Status ASC  )  
	 INCLUDE ( DtUltimaRequisicao , FilaCanalOffLine , FilaCanalTelefone , FilaCanalWhatsApp , GUID , IdContaSistema , IdPessoa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX nci_wi_UsuarioContaSistema_DCEDBE0446505C72DE050527DEAECB31 ON dbo.UsuarioContaSistema (  FilaCanalOnLine ASC  , Status ASC  )  
	 INCLUDE ( DtUltimaRequisicao , FilaCanalOffLine , FilaCanalTelefone , GUID , IdContaSistema , IdPessoa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
ALTER TABLE SuperCRMDB.dbo.UsuarioContaSistema WITH NOCHECK ADD CONSTRAINT CKC_STATUS_USUARIOC CHECK ([Status]='DE' OR [Status]='AT');


-- SuperCRMDB.dbo.DbLocalidadeCEPLogradouro definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.DbLocalidadeCEPLogradouro;

CREATE TABLE SuperCRMDB.dbo.DbLocalidadeCEPLogradouro (
	IdBairro int NOT NULL,
	Nome varchar(1000) COLLATE Latin1_General_CI_AI NOT NULL,
	Complemento varchar(1000) COLLATE Latin1_General_CI_AI NULL,
	UtilizaTipo char(1) COLLATE Latin1_General_CI_AI DEFAULT '1' NULL,
	Tipo varchar(50) COLLATE Latin1_General_CI_AI NULL,
	CEP int NOT NULL,
	Abreviacao varchar(500) COLLATE Latin1_General_CI_AI NULL,
	ID int IDENTITY(1,1) NOT NULL,
	latitude varchar(255) COLLATE Latin1_General_CI_AI NULL,
	longitude varchar(255) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime NOT NULL,
	DtAtualizacao datetime NOT NULL,
	IdUsuarioContaSistema int NULL,
	CONSTRAINT PK_DbLocalidadeCEPLogradouro PRIMARY KEY (ID),
	CONSTRAINT FK83 FOREIGN KEY (IdBairro) REFERENCES SuperCRMDB.dbo.DbLocalidadeBairro(Id) ON DELETE CASCADE,
	CONSTRAINT FK_DBLOCALI_REFERENCE_USUA852 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX idxCEP ON dbo.DbLocalidadeCEPLogradouro (  CEP ASC  , IdBairro ASC  )  
	 INCLUDE ( ID ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdBairro ON dbo.DbLocalidadeCEPLogradouro (  IdBairro ASC  , CEP ASC  )  
	 INCLUDE ( ID ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxUniqueCEP ON dbo.DbLocalidadeCEPLogradouro (  CEP ASC  )  
	 INCLUDE ( IdBairro ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Tag definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Tag;

CREATE TABLE SuperCRMDB.dbo.Tag (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NOT NULL,
	IdUsuarioContaSistema int NULL,
	DtInclusao datetime NOT NULL,
	Valor varchar(300) COLLATE Latin1_General_CI_AI NOT NULL,
	Tipo varchar(30) COLLATE Latin1_General_CI_AI NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	CONSTRAINT PK_TAG PRIMARY KEY (Id),
	CONSTRAINT FK_TAG_REFERENCE_CONTASIS122 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id),
	CONSTRAINT FK_TAG_REFERENCE_USUARIO56 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.Tag (  IdGuid ASC  , IdContaSistema ASC  )  
	 INCLUDE ( Id , Valor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.Tag (  IdContaSistema ASC  , Tipo ASC  )  
	 INCLUDE ( DtInclusao , IdGuid , IdUsuarioContaSistema , Valor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxUnique ON dbo.Tag (  IdContaSistema ASC  , Valor ASC  , Tipo ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxValor ON dbo.Tag (  Valor ASC  , IdContaSistema ASC  , Tipo ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Remessa definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Remessa;

CREATE TABLE SuperCRMDB.dbo.Remessa (
	Id int IDENTITY(1,1) NOT NULL,
	IdUsuarioContaSistema int NULL,
	Status varchar(10) COLLATE Latin1_General_CI_AI DEFAULT 'INC' NOT NULL,
	DtInclusao datetime DEFAULT [dbo].[GetDateCustom]() NOT NULL,
	DtEnvio datetime NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdTransportadora int NOT NULL,
	Tipo varchar(30) COLLATE Latin1_General_CI_AI NOT NULL,
	IdContaSistema int NOT NULL,
	CONSTRAINT PK_REMESSA PRIMARY KEY (Id),
	CONSTRAINT FK_REMESSA_REFERENCE_CONT841 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id) ON DELETE CASCADE,
	CONSTRAINT FK_REMESSA_REFERENCE_COX89A FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id),
	CONSTRAINT FK_REMESSA_REFERENCE_TRANSPOR FOREIGN KEY (IdTransportadora) REFERENCES SuperCRMDB.dbo.Transportadora(Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.Remessa (  IdGuid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxTransportadora ON dbo.Remessa (  IdTransportadora ASC  )  
	 INCLUDE ( Id , IdUsuarioContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxUsuarioContaSistema ON dbo.Remessa (  IdUsuarioContaSistema ASC  , IdTransportadora ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
ALTER TABLE SuperCRMDB.dbo.Remessa WITH NOCHECK ADD CONSTRAINT CKC_STATUS_REMESSA CHECK ([Status]=upper([Status]));


-- SuperCRMDB.dbo.AcaoLote definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.AcaoLote;

CREATE TABLE SuperCRMDB.dbo.AcaoLote (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdContaSistema int NOT NULL,
	IdUsuarioContaSistema int NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	StatusProcessamento varchar(30) COLLATE Latin1_General_CI_AI NOT NULL,
	Tipo varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	QtdTotal int DEFAULT 0 NOT NULL,
	QtdSucesso int DEFAULT 0 NOT NULL,
	QtdErro int DEFAULT 0 NOT NULL,
	DtInclusao datetime NOT NULL,
	DtUltimoAtualizacao datetime NOT NULL,
	ObjJson varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	ObjJsonType varchar(300) COLLATE Latin1_General_CI_AI NULL,
	StrLog varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_ACAOLOTE PRIMARY KEY (Id),
	CONSTRAINT FK_ACAOLOTE_REFERENCE_CON478 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id),
	CONSTRAINT FK_ACAOLOTE_REFERENCE_USU457 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.AcaoLote (  IdContaSistema ASC  , IdUsuarioContaSistema ASC  , StatusProcessamento ASC  )  
	 INCLUDE ( DtInclusao , Tipo ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.AcaoLote (  IdGuid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
ALTER TABLE SuperCRMDB.dbo.AcaoLote WITH NOCHECK ADD CONSTRAINT CKC_OBJJSON_ACAOLOTE CHECK ([ObjJson] IS NULL OR isjson([ObjJson])=(1));


-- SuperCRMDB.dbo.ProdutoCampanha definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.ProdutoCampanha;

CREATE TABLE SuperCRMDB.dbo.ProdutoCampanha (
	Id int IDENTITY(1,1) NOT NULL,
	IdProduto int NOT NULL,
	IdCampanha int NOT NULL,
	CONSTRAINT PK_PRODUTOCAMPANHA PRIMARY KEY (Id,IdProduto,IdCampanha),
	CONSTRAINT FK_PRODUTOC_REFERENCE_CAMPANHA FOREIGN KEY (IdCampanha) REFERENCES SuperCRMDB.dbo.Campanha(Id),
	CONSTRAINT FK_PRODUTOC_REFERENCE_PRODUTO FOREIGN KEY (IdProduto) REFERENCES SuperCRMDB.dbo.Produto(Id)
);
 CREATE NONCLUSTERED INDEX IDXCAMPANHA ON dbo.ProdutoCampanha (  IdCampanha ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX IDXPRODUTO ON dbo.ProdutoCampanha (  IdProduto ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX IDXPRODUTOCAMPANHA ON dbo.ProdutoCampanha (  IdCampanha ASC  , IdProduto ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.CampanhaConfiguracao definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.CampanhaConfiguracao;

CREATE TABLE SuperCRMDB.dbo.CampanhaConfiguracao (
	Id int IDENTITY(1,1) NOT NULL,
	IdCampanha int NOT NULL,
	IdUsuarioContaSistema int NULL,
	Tipo varchar(150) COLLATE Latin1_General_CI_AI NULL,
	Valor varchar(300) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime NOT NULL,
	DtModificacao datetime NULL,
	ValorText varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	ValorInt int NULL,
	CONSTRAINT PK_CAMPANHACONFIGURACAO PRIMARY KEY (Id),
	CONSTRAINT FK_CAMPANHA_REFERENCE_CAMPA896 FOREIGN KEY (IdCampanha) REFERENCES SuperCRMDB.dbo.Campanha(Id) ON DELETE CASCADE,
	CONSTRAINT FK_CAMPANHA_REFERENCE_USUA8756 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id) ON DELETE CASCADE
);
 CREATE NONCLUSTERED INDEX idxTipo ON dbo.CampanhaConfiguracao (  Tipo ASC  , Valor ASC  , IdCampanha ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxTipo2 ON dbo.CampanhaConfiguracao (  Tipo ASC  , ValorInt ASC  , IdCampanha ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxUniqueIdCampanha ON dbo.CampanhaConfiguracao (  IdCampanha ASC  , Tipo ASC  )  
	 INCLUDE ( Valor , ValorInt ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.SuperEntidadeLog definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.SuperEntidadeLog;

CREATE TABLE SuperCRMDB.dbo.SuperEntidadeLog (
	Id int IDENTITY(1,1) NOT NULL,
	IdUsuarioContaSistema int NULL,
	IdSuperEntidade int NOT NULL,
	Texto varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	Tipo varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime DEFAULT [dbo].[GetDateCustom]() NOT NULL,
	CONSTRAINT PK_SUPERENTIDADELOG PRIMARY KEY (Id),
	CONSTRAINT FK_SUPERENT_REFERENCE_SUP788 FOREIGN KEY (IdSuperEntidade) REFERENCES SuperCRMDB.dbo.SuperEntidade(Id) ON DELETE CASCADE,
	CONSTRAINT FK_SUPERENT_REFERENCE_USUARIOC FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX idxIdSuperEntidade ON dbo.SuperEntidadeLog (  IdSuperEntidade ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.CampanhaCanal definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.CampanhaCanal;

CREATE TABLE SuperCRMDB.dbo.CampanhaCanal (
	Id int IDENTITY(1,1) NOT NULL,
	IdCanal int NOT NULL,
	IdCampanha int NOT NULL,
	NumeroMaxAtendimentoSimultaneo int DEFAULT -1 NULL,
	TempoMaxInicioAtendimento int DEFAULT 999 NULL,
	TipoTempoMaxInicioAtendimento varchar(15) COLLATE Latin1_General_CI_AI NULL,
	CanalPadrao bit DEFAULT 0 NOT NULL,
	TipoPrioridade varchar(30) COLLATE Latin1_General_CI_AI DEFAULT 'PADRAO' NULL,
	UsarModuloAtendimento bit DEFAULT 0 NOT NULL,
	CanalPadraoCarteira bit DEFAULT 0 NOT NULL,
	UsarCanalNoAutoEncerrar bit DEFAULT 0 NOT NULL,
	CONSTRAINT PK_CAMPANHACANAL PRIMARY KEY (Id),
	CONSTRAINT FK_CAMPANHA_REFERENCE_CAMPANHA FOREIGN KEY (IdCampanha) REFERENCES SuperCRMDB.dbo.Campanha(Id),
	CONSTRAINT FK_CAMPANHA_REFERENCE_CANAL FOREIGN KEY (IdCanal) REFERENCES SuperCRMDB.dbo.Canal(Id)
);
 CREATE NONCLUSTERED INDEX idxCanal ON dbo.CampanhaCanal (  IdCanal ASC  , IdCampanha ASC  )  
	 INCLUDE ( CanalPadrao , Id , NumeroMaxAtendimentoSimultaneo , UsarCanalNoAutoEncerrar ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdCampanha ON dbo.CampanhaCanal (  IdCampanha ASC  , IdCanal ASC  )  
	 INCLUDE ( CanalPadrao , Id , NumeroMaxAtendimentoSimultaneo , UsarCanalNoAutoEncerrar ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxUsarCanalNoAutoEncerrar ON dbo.CampanhaCanal (  UsarCanalNoAutoEncerrar ASC  )  
	 INCLUDE ( IdCampanha , IdCanal ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Grupo definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Grupo;

CREATE TABLE SuperCRMDB.dbo.Grupo (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NOT NULL,
	Nome varchar(100) COLLATE Latin1_General_CI_AI NOT NULL,
	Padrao bit DEFAULT 0 NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	DtAtualizacao datetime NOT NULL,
	Codigo int NULL,
	Tipo varchar(50) COLLATE Latin1_General_CI_AI NULL,
	Mostrar bit DEFAULT 1 NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	IdTag int NULL,
	versao timestamp NOT NULL,
	CONSTRAINT PK_GRUPO PRIMARY KEY (Id),
	CONSTRAINT FK_GRUPO_REFERENCE125_TAG FOREIGN KEY (IdTag) REFERENCES SuperCRMDB.dbo.Tag(Id) ON DELETE SET DEFAULT,
	CONSTRAINT FK_GRUPO_REFERENCE_CONTASIS FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX idxCodigo ON dbo.Grupo (  Codigo ASC  , IdContaSistema ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxContaSistema ON dbo.Grupo (  IdContaSistema ASC  , Padrao ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxId ON dbo.Grupo (  Id ASC  , IdGuid ASC  , IdContaSistema ASC  )  
	 INCLUDE ( Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdGuid ON dbo.Grupo (  IdGuid ASC  )  
	 INCLUDE ( Id , IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxNome ON dbo.Grupo (  Nome ASC  )  
	 INCLUDE ( Id , IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxStatus ON dbo.Grupo (  Status ASC  , IdContaSistema ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxVersao ON dbo.Grupo (  versao ASC  , Id ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX nci_wi_Grupo_98425FF6A6CDA6C6513D777223CA9DD3 ON dbo.Grupo (  IdTag ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.CampanhaGrupo definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.CampanhaGrupo;

CREATE TABLE SuperCRMDB.dbo.CampanhaGrupo (
	Id int IDENTITY(1,1) NOT NULL,
	IdGrupo int NOT NULL,
	IdCampanha int NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	DtModificacao datetime NOT NULL,
	CONSTRAINT PK_CAMPANHAGRUPO PRIMARY KEY (Id),
	CONSTRAINT FK_CAMPANHA_REFERENCE_CAMPANH1 FOREIGN KEY (IdCampanha) REFERENCES SuperCRMDB.dbo.Campanha(Id),
	CONSTRAINT FK_CAMPANHA_REFERENCE_GRUP20 FOREIGN KEY (IdGrupo) REFERENCES SuperCRMDB.dbo.Grupo(Id) ON DELETE CASCADE
);
 CREATE NONCLUSTERED INDEX idxStatus ON dbo.CampanhaGrupo (  Status ASC  , IdGrupo ASC  )  
	 INCLUDE ( IdCampanha ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxUniqueIdCampanha ON dbo.CampanhaGrupo (  IdCampanha ASC  , IdGrupo ASC  )  
	 INCLUDE ( Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxUniqueIdGrupo ON dbo.CampanhaGrupo (  IdGrupo ASC  , IdCampanha ASC  )  
	 INCLUDE ( Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.PessoaProspectImportacao definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PessoaProspectImportacao;

CREATE TABLE SuperCRMDB.dbo.PessoaProspectImportacao (
	Id int IDENTITY(1,1) NOT NULL,
	Nome varchar(300) COLLATE Latin1_General_CI_AI NOT NULL,
	Descricao varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	ResumoImportacao varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime NOT NULL,
	QtdTotal int DEFAULT 0 NULL,
	QtdSucesso int DEFAULT 0 NULL,
	QtdErro int DEFAULT 0 NULL,
	idContaSistema int NOT NULL,
	QtdNovosProspects int DEFAULT 0 NULL,
	QtdVelhosProspects int DEFAULT 0 NULL,
	DtFimInclusao datetime NULL,
	SobrescreverProspects bit DEFAULT 1 NOT NULL,
	StrGuid char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	Status varchar(30) COLLATE Latin1_General_CI_AI DEFAULT 'PROCESSADO' NOT NULL,
	DtUltimoAtualizacao datetime NULL,
	IdUsuarioContaSistema int NULL,
	QtdUnicosProspects int DEFAULT 0 NULL,
	CONSTRAINT PK_PESSOAPROSPECTIMPORTACAO PRIMARY KEY (Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_CONTA99 FOREIGN KEY (idContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_USUA4587 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX idxContaSistema ON dbo.PessoaProspectImportacao (  idContaSistema ASC  , Status ASC  , DtInclusao ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxStatus ON dbo.PessoaProspectImportacao (  Status ASC  , DtInclusao ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Resposta definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Resposta;

CREATE TABLE SuperCRMDB.dbo.Resposta (
	Id int IDENTITY(1,1) NOT NULL,
	IdPergunta int NOT NULL,
	TextoResposta varchar(8000) COLLATE Latin1_General_CI_AI NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	Peso int DEFAULT 0 NOT NULL,
	idGuid char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	CONSTRAINT PK_RESPOSTA PRIMARY KEY (Id),
	CONSTRAINT FK_RESPOSTA_REFERENCE_PERGUNT1 FOREIGN KEY (IdPergunta) REFERENCES SuperCRMDB.dbo.Pergunta(Id)
);


-- SuperCRMDB.dbo.PlantaoHorario definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PlantaoHorario;

CREATE TABLE SuperCRMDB.dbo.PlantaoHorario (
	Id int IDENTITY(1,1) NOT NULL,
	IdPlantao int NOT NULL,
	DtInicio datetime NOT NULL,
	DtFim datetime NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_PLANTAOHORARIO PRIMARY KEY (Id),
	CONSTRAINT FK_PLANTAOH_REFERENCE_PLANTAO FOREIGN KEY (IdPlantao) REFERENCES SuperCRMDB.dbo.Plantao(Id) ON DELETE CASCADE
);
 CREATE NONCLUSTERED INDEX idxDtInicio ON dbo.PlantaoHorario (  DtInicio ASC  , DtFim ASC  , Status ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdPlantao ON dbo.PlantaoHorario (  IdPlantao ASC  , Status ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX nci_wi_PlantaoHorario_D79523595A804F480265B0B357E90DD0 ON dbo.PlantaoHorario (  DtFim ASC  )  
	 INCLUDE ( DtInicio , IdPlantao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX nci_wi_PlantaoHorario_EB15864B2F3C15602392F94287391B68 ON dbo.PlantaoHorario (  Status ASC  , DtFim ASC  )  
	 INCLUDE ( DtInicio , IdPlantao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.GrupoSuperior definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.GrupoSuperior;

CREATE TABLE SuperCRMDB.dbo.GrupoSuperior (
	Id int IDENTITY(1,1) NOT NULL,
	IdGrupo int NOT NULL,
	IdGrupoSuperior int NOT NULL,
	DtInicio datetime NOT NULL,
	DtFim datetime NULL,
	StatusRegistroBach char(2) COLLATE Latin1_General_CI_AI DEFAULT 'DE' NOT NULL,
	versao timestamp NOT NULL,
	CONSTRAINT PK_GRUPOSUPERIOR PRIMARY KEY (Id),
	CONSTRAINT FK_GRUPOSUP_REFERENCE_GRUP25 FOREIGN KEY (IdGrupo) REFERENCES SuperCRMDB.dbo.Grupo(Id),
	CONSTRAINT FK_GRUPOSUP_REFERENCE_GRUP26 FOREIGN KEY (IdGrupoSuperior) REFERENCES SuperCRMDB.dbo.Grupo(Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.GrupoSuperior (  IdGrupo ASC  , IdGrupoSuperior ASC  , DtFim ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Topico definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Topico;

CREATE TABLE SuperCRMDB.dbo.Topico (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	Titulo varchar(3000) COLLATE Latin1_General_CI_AI NOT NULL,
	Texto varchar(3000) COLLATE Latin1_General_CI_AI NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	Tipo varchar(30) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	DtAlteracao datetime NULL,
	CONSTRAINT PK_TOPICO PRIMARY KEY (Id),
	CONSTRAINT FK_TOPICO_REFERENCE_CONTASIS5 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id),
	CONSTRAINT FK_TOPICO_REFERENCE_USUARIOC96 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX IDX1 ON dbo.Topico (  IdContaSistema ASC  , Status ASC  , Titulo ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Relatorio definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Relatorio;

CREATE TABLE SuperCRMDB.dbo.Relatorio (
	Id int IDENTITY(1,1) NOT NULL,
	IdRelatorioGrupo int NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	IdRelatorioPai int NULL,
	Permissao varchar(500) COLLATE Latin1_General_CI_AI NULL,
	Nome varchar(500) COLLATE Latin1_General_CI_AI NULL,
	Descricao varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	UrlFiltro varchar(1000) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime NOT NULL,
	Tipo varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	HerdarGrupo bit NOT NULL,
	LayoutString varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	CollapsedStateString varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	HerdarConfiguracao bit DEFAULT 0 NOT NULL,
	Manutencao bit DEFAULT 0 NOT NULL,
	TipoAbertura varchar(20) COLLATE Latin1_General_CI_AI DEFAULT 'NORMAL' NULL,
	idGuid char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	ObjTipo varchar(400) COLLATE Latin1_General_CI_AI NULL,
	ObjJson varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_RELATORIO PRIMARY KEY (Id),
	CONSTRAINT FK_RELATORI_REFERENCE_RELA788 FOREIGN KEY (IdRelatorioGrupo) REFERENCES SuperCRMDB.dbo.RelatorioGrupo(Id),
	CONSTRAINT FK_RELATORI_REFERENCE_RELATORI FOREIGN KEY (IdRelatorioPai) REFERENCES SuperCRMDB.dbo.Relatorio(Id),
	CONSTRAINT FK_RELATORI_REFERENCE_USUAQ872 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.Relatorio (  idGuid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.GrupoAux definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.GrupoAux;

CREATE TABLE SuperCRMDB.dbo.GrupoAux (
	Id int NOT NULL,
	GrupoHierarquia varchar(1000) COLLATE Latin1_General_CI_AI NULL,
	GrupoHierarquiaTipo varchar(1000) COLLATE Latin1_General_CI_AI NULL,
	NivelGeral int NULL,
	CONSTRAINT PK_GRUPOAUX PRIMARY KEY (Id),
	CONSTRAINT FK_GRUPOAUX_REFERENCE_GRUAX FOREIGN KEY (Id) REFERENCES SuperCRMDB.dbo.Grupo(Id) ON DELETE CASCADE
);


-- SuperCRMDB.dbo.ContaSistemaConfiguracao definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.ContaSistemaConfiguracao;

CREATE TABLE SuperCRMDB.dbo.ContaSistemaConfiguracao (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NOT NULL,
	IdUsuarioContaSistema int NULL,
	Tipo varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	Valor varchar(300) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime NOT NULL,
	DtModificacao datetime NULL,
	ValorInt int DEFAULT 0 NULL,
	Status char(2) COLLATE Latin1_General_CI_AI DEFAULT 'AT' NOT NULL,
	ValorObj varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	ObjTipo varchar(1000) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_CONTASISTEMACONFIGURACAO PRIMARY KEY (Id),
	CONSTRAINT FK_CONTASIS_REFERENCE_CONTA589 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id),
	CONSTRAINT FK_CONTASIS_REFERENCE_USUA8533 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.ContaSistemaConfiguracao (  IdContaSistema ASC  , Tipo ASC  )  
	 INCLUDE ( Id , Status , Valor , ValorInt ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.TopicoProduto definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.TopicoProduto;

CREATE TABLE SuperCRMDB.dbo.TopicoProduto (
	Id int IDENTITY(1,1) NOT NULL,
	IdTopico int NOT NULL,
	IdProduto int NOT NULL,
	DtInclusao datetime NOT NULL,
	CONSTRAINT PK_TOPICOPRODUTO PRIMARY KEY (Id),
	CONSTRAINT FK_TOPICOPR_REFERENCE_PRODUTO33 FOREIGN KEY (IdProduto) REFERENCES SuperCRMDB.dbo.Produto(Id) ON DELETE CASCADE,
	CONSTRAINT FK_TOPICOPR_REFERENCE_TOP856 FOREIGN KEY (IdTopico) REFERENCES SuperCRMDB.dbo.Topico(Id) ON DELETE CASCADE
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.TopicoProduto (  IdTopico ASC  , IdProduto ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.TopicoArquivo definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.TopicoArquivo;

CREATE TABLE SuperCRMDB.dbo.TopicoArquivo (
	Id int IDENTITY(1,1) NOT NULL,
	StrGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	IdTopico int NOT NULL,
	DtInclusao datetime NOT NULL,
	Descricao varchar(1000) COLLATE Latin1_General_CI_AI NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	TipoArquivo varchar(10) COLLATE Latin1_General_CI_AI NOT NULL,
	Tamanho int NOT NULL,
	Extensao varchar(6) COLLATE Latin1_General_CI_AI NULL,
	Complemento varchar(3000) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_TOPICOARQUIVO PRIMARY KEY (Id),
	CONSTRAINT FK_TOPICOAR_REFERENCE_TOPICO96 FOREIGN KEY (IdTopico) REFERENCES SuperCRMDB.dbo.Topico(Id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT FK_TOPICOAR_REFERENCE_USUARIOC23 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id) ON DELETE CASCADE
);
 CREATE NONCLUSTERED INDEX IDX1 ON dbo.TopicoArquivo (  IdTopico ASC  , Status ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.ImportacaoValidacaoTemp definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.ImportacaoValidacaoTemp;

CREATE TABLE SuperCRMDB.dbo.ImportacaoValidacaoTemp (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	Nome varchar(300) COLLATE Latin1_General_CI_AI NULL,
	Descricao varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	QtdTotalRegistros int DEFAULT 0 NOT NULL,
	QtdTotalValidado int DEFAULT 0 NOT NULL,
	QtdTotalErros int DEFAULT 0 NOT NULL,
	QtdTotalSemErros int DEFAULT 0 NOT NULL,
	QtdMaximaLote int DEFAULT 0 NOT NULL,
	QtdLotes int DEFAULT 0 NOT NULL,
	QtdLotesValidados int DEFAULT 0 NOT NULL,
	SobrescreverProspects bit DEFAULT 1 NOT NULL,
	Status varchar(30) COLLATE Latin1_General_CI_AI DEFAULT 'INCLUIDO' NOT NULL,
	DtInclusao datetime NOT NULL,
	DtFimValidacao datetime NULL,
	DtUltimaAtualizacao datetime NULL,
	Error varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	Tipo varchar(30) COLLATE Latin1_General_CI_AI NOT NULL,
	StorageDir varchar(1024) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT pk_ImportacaoValidacaoTemp PRIMARY KEY (Id),
	CONSTRAINT ref_ImportacaoValidacaoTemp_ContaSistema FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id),
	CONSTRAINT ref_ImportacaoValidacaoTemp_UsuarioContaSistema FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX idxImportacaoValidacaoTempUsuarioContaSistema ON dbo.ImportacaoValidacaoTemp (  IdContaSistema ASC  , IdUsuarioContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxidxImportacaoValidacaoTempUsuarioContaSistemaIdGuid ON dbo.ImportacaoValidacaoTemp (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.CanalExpurgo definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.CanalExpurgo;

CREATE TABLE SuperCRMDB.dbo.CanalExpurgo (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdCanal int NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	DtValidade date NULL,
	DiaSemanaExpurgo smallint NOT NULL,
	TimeExpurgo time NOT NULL,
	DtUltimoExpurgoExecutado date NULL,
	DtUltimoExpurgoExecutadoFull datetime NULL,
	Acao varchar(15) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_CANALEXPURGO PRIMARY KEY (Id),
	CONSTRAINT FK_CANALEXP_REFERENCE_CA258 FOREIGN KEY (IdCanal) REFERENCES SuperCRMDB.dbo.Canal(Id) ON DELETE CASCADE,
	CONSTRAINT FK_CANALEXP_REFERENCE_USU4587 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id) ON DELETE CASCADE
);
 CREATE NONCLUSTERED INDEX nci_wi_CanalExpurgo_6E4A7B92E65B8C633A2179E3E7CFBDEA ON dbo.CanalExpurgo (  DiaSemanaExpurgo ASC  , TimeExpurgo ASC  , IdCanal ASC  )  
	 INCLUDE ( Acao , DtInclusao , DtUltimoExpurgoExecutado , DtUltimoExpurgoExecutadoFull , DtValidade , IdGuid , IdUsuarioContaSistema , Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.IntegradoraExterna definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.IntegradoraExterna;

CREATE TABLE SuperCRMDB.dbo.IntegradoraExterna (
	Id int IDENTITY(1,1) NOT NULL,
	StrKey char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	Nome varchar(200) COLLATE Latin1_General_CI_AI NOT NULL,
	EmailResponsavel varchar(400) COLLATE Latin1_General_CI_AI NULL,
	ContatoResponsavel varchar(300) COLLATE Latin1_General_CI_AI NULL,
	TelefoneResponsavel varchar(200) COLLATE Latin1_General_CI_AI NULL,
	Obs varchar(3000) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime NOT NULL,
	DtAtualizacao datetime NOT NULL,
	Tipo varchar(150) COLLATE Latin1_General_CI_AI NOT NULL,
	Site varchar(1000) COLLATE Latin1_General_CI_AI NULL,
	Identificador varchar(1000) COLLATE Latin1_General_CI_AI NULL,
	Publico bit DEFAULT 1 NOT NULL,
	ExtensaoLogo varchar(5) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_INTEGRADORAEXTERNA PRIMARY KEY (Id),
	CONSTRAINT FK_INTEGRAD_REFERENCE_USUAR832 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id) ON DELETE CASCADE ON UPDATE CASCADE
);
 CREATE NONCLUSTERED INDEX idxIdentificador ON dbo.IntegradoraExterna (  Identificador ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxNome ON dbo.IntegradoraExterna (  Nome ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxStrKey ON dbo.IntegradoraExterna (  StrKey ASC  , Status ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.IntegradoraExternaContaSistema definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.IntegradoraExternaContaSistema;

CREATE TABLE SuperCRMDB.dbo.IntegradoraExternaContaSistema (
	Id int IDENTITY(1,1) NOT NULL,
	IdIntegradoraExterna int NOT NULL,
	IdContaSistema int NOT NULL,
	DtInclusao datetime NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	CONSTRAINT PK_INTEGRADORAEXTERNACONTASIST PRIMARY KEY (Id),
	CONSTRAINT FK_INTEGRAD_REFERENCE_CONTA632 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id) ON DELETE CASCADE,
	CONSTRAINT FK_INTEGRAD_REFERENCE_INTEG458 FOREIGN KEY (IdIntegradoraExterna) REFERENCES SuperCRMDB.dbo.IntegradoraExterna(Id) ON DELETE CASCADE,
	CONSTRAINT FK_INTEGRAD_REFERENCE_USUAR78 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX IDX1 ON dbo.IntegradoraExternaContaSistema (  IdContaSistema ASC  , IdIntegradoraExterna ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.IntegradoraExternaContaSistema (  IdIntegradoraExterna ASC  , IdContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.PoliticaDePrivacidade definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PoliticaDePrivacidade;

CREATE TABLE SuperCRMDB.dbo.PoliticaDePrivacidade (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdContaSistema int NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	DtModificacao datetime NOT NULL,
	Tipo varchar(20) COLLATE Latin1_General_CI_AI NOT NULL,
	ObjJson varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	ObjTipo varchar(500) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_POLITICADEPRIVACIDADE PRIMARY KEY (Id),
	CONSTRAINT FK_POLITICA_REFERENCE_CON856 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id),
	CONSTRAINT FK_POLITICA_REFERENCE_USUARIOC FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX idContaSistema ON dbo.PoliticaDePrivacidade (  IdContaSistema ASC  , Tipo ASC  )  
	 INCLUDE ( Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.PoliticaDePrivacidade (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Gatilho definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Gatilho;

CREATE TABLE SuperCRMDB.dbo.Gatilho (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	DtInclusao datetime NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	DtAlteracao datetime NULL,
	EventoTipo varchar(100) COLLATE Latin1_General_CI_AI NOT NULL,
	Tipo varchar(100) COLLATE Latin1_General_CI_AI NOT NULL,
	IdCampanha int NULL,
	DtUltimaExecucao datetime NULL,
	GatilhoFiltroHashSHA1 char(40) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_GATILHO PRIMARY KEY (Id),
	CONSTRAINT FK_GATILHO_REFERENCE_CAMPA458 FOREIGN KEY (IdCampanha) REFERENCES SuperCRMDB.dbo.Campanha(Id) ON DELETE CASCADE,
	CONSTRAINT FK_GATILHO_REFERENCE_CONT665 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id),
	CONSTRAINT FK_GATILHO_REFERENCE_TIPOE965 FOREIGN KEY (EventoTipo) REFERENCES SuperCRMDB.dbo.EventoTipo(Tipo) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT FK_GATILHO_REFERENCE_USUAR458 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.Gatilho (  IdContaSistema ASC  , IdCampanha ASC  , EventoTipo ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxEventoTipo ON dbo.Gatilho (  EventoTipo ASC  , Status ASC  , DtUltimaExecucao ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.GatilhoAcao definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.GatilhoAcao;

CREATE TABLE SuperCRMDB.dbo.GatilhoAcao (
	Id int IDENTITY(1,1) NOT NULL,
	IdGatilho int NOT NULL,
	IdAcao int NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	DtInclusao datetime NOT NULL,
	GatilhoAcaoFiltroHashSHA1 char(40) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_GATILHOACAO PRIMARY KEY (Id),
	CONSTRAINT FK_GATILHOA_REFERENCE_AC698 FOREIGN KEY (IdAcao) REFERENCES SuperCRMDB.dbo.Acao(Id) ON DELETE CASCADE,
	CONSTRAINT FK_GATILHOA_REFERENCE_GAT455 FOREIGN KEY (IdGatilho) REFERENCES SuperCRMDB.dbo.Gatilho(Id) ON DELETE CASCADE
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.GatilhoAcao (  IdGatilho ASC  , IdAcao ASC  )  
	 INCLUDE ( GatilhoAcaoFiltroHashSHA1 ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdAcao ON dbo.GatilhoAcao (  IdAcao ASC  , IdGatilho ASC  )  
	 INCLUDE ( GatilhoAcaoFiltroHashSHA1 ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.PoliticaDePrivacidadeUsuarioContaSistema definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PoliticaDePrivacidadeUsuarioContaSistema;

CREATE TABLE SuperCRMDB.dbo.PoliticaDePrivacidadeUsuarioContaSistema (
	Id int IDENTITY(1,1) NOT NULL,
	IdPoliticaDePrivacidade int NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	DtInclusao datetime NOT NULL,
	ObjJson varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	ObjTipo varchar(500) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_POLITICADEPRIVACIDADEUSUARI PRIMARY KEY (Id),
	CONSTRAINT FK_POLITICA_REFERENCE_POLIT783 FOREIGN KEY (IdPoliticaDePrivacidade) REFERENCES SuperCRMDB.dbo.PoliticaDePrivacidade(Id),
	CONSTRAINT FK_POLITICA_REFERENCE_USUA589 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX idxIdPoliticaDePrivacidade ON dbo.PoliticaDePrivacidadeUsuarioContaSistema (  IdPoliticaDePrivacidade ASC  , IdUsuarioContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdUsuarioContaSistema ON dbo.PoliticaDePrivacidadeUsuarioContaSistema (  IdUsuarioContaSistema ASC  , IdPoliticaDePrivacidade ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.IntegracaoRestricao definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.IntegracaoRestricao;

CREATE TABLE SuperCRMDB.dbo.IntegracaoRestricao (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdContaSistema int NULL,
	IdUsuarioContaSistema int NOT NULL,
	Valor varchar(600) COLLATE Latin1_General_CI_AI NOT NULL,
	ValorTipo varchar(30) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	Tipo varchar(30) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_INTEGRACAORESTRICAO PRIMARY KEY (Id),
	CONSTRAINT FK_RESTRICA_REFERENCE_CONT85 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id),
	CONSTRAINT FK_RESTRICA_REFERENCE_USUA856 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.IntegracaoRestricao (  IdGuid ASC  )  
	 INCLUDE ( IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxValor ON dbo.IntegracaoRestricao (  Valor ASC  , ValorTipo ASC  , Tipo ASC  )  
	 INCLUDE ( IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.RelatorioContaSistema definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.RelatorioContaSistema;

CREATE TABLE SuperCRMDB.dbo.RelatorioContaSistema (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NOT NULL,
	IdRelatorio int NOT NULL,
	DtInclusao datetime NOT NULL,
	CONSTRAINT PK_RELATORIOCONTASISTEMA PRIMARY KEY (Id),
	CONSTRAINT FK_RELATORI_REFERENCE_CONT458 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id),
	CONSTRAINT FK_RELATORI_REFERENCE_RELA45451 FOREIGN KEY (IdRelatorio) REFERENCES SuperCRMDB.dbo.Relatorio(Id) ON DELETE CASCADE
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxUnique ON dbo.RelatorioContaSistema (  IdRelatorio ASC  , IdContaSistema ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.TemplateIntegracaoIntegradoraExterna definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.TemplateIntegracaoIntegradoraExterna;

CREATE TABLE SuperCRMDB.dbo.TemplateIntegracaoIntegradoraExterna (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdTemplateIntegracao int NOT NULL,
	IdIntegradoraExterna int NOT NULL,
	CONSTRAINT PK_TEMPLATEINTEGRACAOINTEGRADO PRIMARY KEY (Id),
	CONSTRAINT FK_TEMPLATE_REFERENCE_IN2154 FOREIGN KEY (IdIntegradoraExterna) REFERENCES SuperCRMDB.dbo.IntegradoraExterna(Id),
	CONSTRAINT FK_TEMPLATE_REFERENCE_TEMP45 FOREIGN KEY (IdTemplateIntegracao) REFERENCES SuperCRMDB.dbo.TemplateIntegracao(Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX idx1 ON dbo.TemplateIntegracaoIntegradoraExterna (  IdTemplateIntegracao ASC  , IdIntegradoraExterna ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.TemplateIntegracaoIntegradoraExterna (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdIntegradoraExterna ON dbo.TemplateIntegracaoIntegradoraExterna (  IdIntegradoraExterna ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdTemplateIntegracao ON dbo.TemplateIntegracaoIntegradoraExterna (  IdTemplateIntegracao ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.ContaSistemaLog definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.ContaSistemaLog;

CREATE TABLE SuperCRMDB.dbo.ContaSistemaLog (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NOT NULL,
	IdUsuarioContaSistema int NULL,
	Text varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	Valor varchar(1000) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime DEFAULT [dbo].[GetDateCustom]() NOT NULL,
	Tipo varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_CONTASISTEMALOG PRIMARY KEY (Id),
	CONSTRAINT FK_CONTASIS_REFERENCE_CONX852 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id),
	CONSTRAINT FK_CONTASIS_REFERENCE_USUAW787 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX IDXCONTASISTEMA ON dbo.ContaSistemaLog (  IdContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.ProdutoLog definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.ProdutoLog;

CREATE TABLE SuperCRMDB.dbo.ProdutoLog (
	Id int IDENTITY(1,1) NOT NULL,
	IdProduto int NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	Descricao varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	CONSTRAINT PK_PRODUTOLOG PRIMARY KEY (Id),
	CONSTRAINT FK_PRODUTOL_REFERENCE_PRO4596 FOREIGN KEY (IdProduto) REFERENCES SuperCRMDB.dbo.Produto(Id),
	CONSTRAINT FK_PRODUTOL_REFERENCE_USUW457 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);


-- SuperCRMDB.dbo.GatilhoAcaoAcaoVariavel definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.GatilhoAcaoAcaoVariavel;

CREATE TABLE SuperCRMDB.dbo.GatilhoAcaoAcaoVariavel (
	Id int IDENTITY(1,1) NOT NULL,
	IdUsuarioContaSistema int NULL,
	IdGatilhoAcao int NOT NULL,
	IdAcaoVariavel int NOT NULL,
	Valor varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime NOT NULL,
	DtModificacao datetime NULL,
	Ativo bit DEFAULT 1 NOT NULL,
	CONSTRAINT PK_GATILHOACAOACAOVARIAVEL PRIMARY KEY (Id),
	CONSTRAINT FK_GATILHOA_REFERENCE_ACAOVARI45 FOREIGN KEY (IdAcaoVariavel) REFERENCES SuperCRMDB.dbo.AcaoVariavel(Id),
	CONSTRAINT FK_GATILHOA_REFERENCE_GATILHOA34 FOREIGN KEY (IdGatilhoAcao) REFERENCES SuperCRMDB.dbo.GatilhoAcao(Id) ON DELETE CASCADE,
	CONSTRAINT FK_GATILHOA_REFERENCE_USUARIO209 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);


-- SuperCRMDB.dbo.GatilhoExecucao definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.GatilhoExecucao;

CREATE TABLE SuperCRMDB.dbo.GatilhoExecucao (
	Id int IDENTITY(1,1) NOT NULL,
	StrGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdGatilho int NOT NULL,
	GatilhoFiltroHashSHA1 char(40) COLLATE Latin1_General_CI_AI NULL,
	IdAcao int NOT NULL,
	GatilhoAcaoFiltroHashSHA1 char(40) COLLATE Latin1_General_CI_AI NULL,
	Status varchar(100) COLLATE Latin1_General_CI_AI NOT NULL,
	CodigoIdentificadorStr varchar(200) COLLATE Latin1_General_CI_AI NULL,
	CodigoIdentificadorInt int NULL,
	DtInclusao datetime NOT NULL,
	DtAlteracao datetime NULL,
	DtValidade datetime NULL,
	CONSTRAINT PK_GATILHOEXECUCAO PRIMARY KEY (Id),
	CONSTRAINT FK_GATILHOE_REFERENCE_ACAO FOREIGN KEY (IdAcao) REFERENCES SuperCRMDB.dbo.Acao(Id) ON DELETE CASCADE,
	CONSTRAINT FK_GATILHOE_REFERENCE_GA4545 FOREIGN KEY (IdGatilho) REFERENCES SuperCRMDB.dbo.Gatilho(Id) ON DELETE CASCADE
);
 CREATE NONCLUSTERED INDEX IDX1 ON dbo.GatilhoExecucao (  IdGatilho ASC  , IdAcao ASC  , Status ASC  , CodigoIdentificadorStr ASC  , GatilhoFiltroHashSHA1 ASC  , GatilhoAcaoFiltroHashSHA1 ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX IDX2 ON dbo.GatilhoExecucao (  IdGatilho ASC  , IdAcao ASC  , Status ASC  , CodigoIdentificadorInt ASC  , GatilhoFiltroHashSHA1 ASC  , GatilhoAcaoFiltroHashSHA1 ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX IDX3 ON dbo.GatilhoExecucao (  IdGatilho ASC  , GatilhoFiltroHashSHA1 ASC  , GatilhoAcaoFiltroHashSHA1 ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX IDX4 ON dbo.GatilhoExecucao (  Status ASC  , DtValidade ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX IDX5 ON dbo.GatilhoExecucao (  StrGuid ASC  )  
	 INCLUDE ( Id , Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx6 ON dbo.GatilhoExecucao (  DtValidade ASC  , Status ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Mensagem definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Mensagem;

CREATE TABLE SuperCRMDB.dbo.Mensagem (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	IdContaSistema int NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	Tipo varchar(50) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime NOT NULL,
	DtValidade datetime NULL,
	Versao timestamp NOT NULL,
	CONSTRAINT PK_MENSAGEM PRIMARY KEY (Id),
	CONSTRAINT rf_Mensagem_ContaSistema FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id),
	CONSTRAINT rf_Mensagem_UsuarioContaSistema FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);


-- SuperCRMDB.dbo.MensagemNotificacao definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.MensagemNotificacao;

CREATE TABLE SuperCRMDB.dbo.MensagemNotificacao (
	Id int IDENTITY(1,1) NOT NULL,
	IdMensagem int NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	Tipo varchar(20) COLLATE Latin1_General_CI_AI NOT NULL,
	Lido bit DEFAULT 0 NOT NULL,
	DtInclusao datetime NOT NULL,
	DtLeitura datetime NULL,
	DtEnvio datetime NULL,
	Versao timestamp NOT NULL,
	IdContaSistema int DEFAULT 0 NOT NULL,
	IdUsuarioContaSistema int DEFAULT 0 NOT NULL,
	CONSTRAINT PK_MENSAGEMNOTIFICACAO PRIMARY KEY (Id),
	CONSTRAINT ref_Notificacao_Mensagem FOREIGN KEY (IdMensagem) REFERENCES SuperCRMDB.dbo.Mensagem(Id) ON DELETE CASCADE
);


-- SuperCRMDB.dbo.MensagemNotificacaoObj definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.MensagemNotificacaoObj;

CREATE TABLE SuperCRMDB.dbo.MensagemNotificacaoObj (
	IdNotificacao int NOT NULL,
	ObjTipo varchar(300) COLLATE Latin1_General_CI_AI NOT NULL,
	ObjJson varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	ObjVersao int NOT NULL,
	Versao timestamp NOT NULL,
	CONSTRAINT PK_MENSAGEMNOTIFICACAOOBJ PRIMARY KEY (IdNotificacao),
	CONSTRAINT FK_MensagemNotificacao_MensagemNotificacaoObj FOREIGN KEY (IdNotificacao) REFERENCES SuperCRMDB.dbo.MensagemNotificacao(Id) ON DELETE CASCADE
);
ALTER TABLE SuperCRMDB.dbo.MensagemNotificacaoObj WITH NOCHECK ADD CONSTRAINT CKC_OBJJSON_MensagemNotificacaoObj CHECK (isjson([ObjJson])=(1));


-- SuperCRMDB.dbo.MensagemObj definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.MensagemObj;

CREATE TABLE SuperCRMDB.dbo.MensagemObj (
	IdMensagem int NOT NULL,
	ObjTipo varchar(300) COLLATE Latin1_General_CI_AI NOT NULL,
	ObjJson varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	ObjVersao int NOT NULL,
	Versao timestamp NOT NULL,
	CONSTRAINT PK_MENSAGEMOBJ PRIMARY KEY (IdMensagem),
	CONSTRAINT FK_Mensagem_MensagemObj FOREIGN KEY (IdMensagem) REFERENCES SuperCRMDB.dbo.Mensagem(Id) ON DELETE CASCADE
);
ALTER TABLE SuperCRMDB.dbo.MensagemObj WITH NOCHECK ADD CONSTRAINT CKC_OBJJSON_MensagemObj CHECK (isjson([ObjJson])=(1));


-- SuperCRMDB.dbo.Nota definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Nota;

CREATE TABLE SuperCRMDB.dbo.Nota (
	Id int IDENTITY(1,1) NOT NULL,
	IdSuperEntidade int NOT NULL,
	IdUsuarioContaSistema int NULL,
	Titulo varchar(300) COLLATE Latin1_General_CI_AI NULL,
	Texto varchar(5000) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime DEFAULT [dbo].[GetDateCustom]() NOT NULL,
	CONSTRAINT PK_NOTA PRIMARY KEY (Id),
	CONSTRAINT FK_NOTA_REFERENCE_SUPE001 FOREIGN KEY (IdSuperEntidade) REFERENCES SuperCRMDB.dbo.SuperEntidade(Id) ON DELETE CASCADE,
	CONSTRAINT FK_NOTA_REFERENCE_USUAN089 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX IDXSUPERENTIDADE ON dbo.Nota (  IdSuperEntidade ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX IDXUSUARIOCONTASISTEMA ON dbo.Nota (  IdUsuarioContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.NotificacaoGlobal definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.NotificacaoGlobal;

CREATE TABLE SuperCRMDB.dbo.NotificacaoGlobal (
	Id int IDENTITY(1,1) NOT NULL,
	StrGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdContaSistema int NOT NULL,
	Tipo varchar(200) COLLATE Latin1_General_CI_AI NOT NULL,
	OrigemCriacao varchar(150) COLLATE Latin1_General_CI_AI NOT NULL,
	ReferenciaEntidade varchar(150) COLLATE Latin1_General_CI_AI NULL,
	ReferenciaEntidadeCodigoInt int NULL,
	ReferenciaEntidadeCodigoStr varchar(300) COLLATE Latin1_General_CI_AI NULL,
	CodigoIdentificadorEntidade varchar(150) COLLATE Latin1_General_CI_AI NULL,
	CodigoIdentificadorStr varchar(400) COLLATE Latin1_General_CI_AI NULL,
	CodigoIdentificadorInt int NULL,
	IdUsuarioContaSistemaCriou int NULL,
	IdUsuarioContaSistemaResponsavel int NULL,
	IdUsuarioContaSistemaUltimoStatus int NULL,
	DtUltimoStatus datetime NOT NULL,
	DtValidade datetime NULL,
	DtInclusao datetime NOT NULL,
	DtAlteracao datetime NULL,
	Status varchar(150) COLLATE Latin1_General_CI_AI NOT NULL,
	ConteudoTipo varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	ConteudoTemplate varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	ConteudoStr varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	ObjSerializadoTipo varchar(300) COLLATE Latin1_General_CI_AI DEFAULT 'CSHARP' NULL,
	ObjSerializado varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	GrauDeImportancia int DEFAULT 0 NOT NULL,
	AvisoStatus varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	AvisoDtUltimoStatus datetime NOT NULL,
	TipoNotificacao varchar(300) COLLATE Latin1_General_CI_AI NOT NULL,
	Identificacao varchar(500) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_NOTIFICACAOGLOBAL PRIMARY KEY (Id),
	CONSTRAINT FK_NOTIFICA_REFERENCE_CON8326 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id),
	CONSTRAINT FK_NOTIFICA_REFERENCE_USU336 FOREIGN KEY (IdUsuarioContaSistemaResponsavel) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id),
	CONSTRAINT FK_NOTIFICA_REFERENCE_USU452 FOREIGN KEY (IdUsuarioContaSistemaUltimoStatus) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id),
	CONSTRAINT FK_NOTIFICA_REFERENCE_USUAR487 FOREIGN KEY (IdUsuarioContaSistemaCriou) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDXGUID ON dbo.NotificacaoGlobal (  StrGuid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idx1 ON dbo.NotificacaoGlobal (  AvisoStatus DESC  , Id DESC  , IdUsuarioContaSistemaResponsavel ASC  , Status ASC  , DtValidade ASC  )  
	 INCLUDE ( IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2 ON dbo.NotificacaoGlobal (  Status ASC  , Identificacao ASC  , TipoNotificacao ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx3 ON dbo.NotificacaoGlobal (  CodigoIdentificadorEntidade ASC  , CodigoIdentificadorInt ASC  , ReferenciaEntidade ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.ProdutoTag definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.ProdutoTag;

CREATE TABLE SuperCRMDB.dbo.ProdutoTag (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	IdTag int NOT NULL,
	IdProduto int NOT NULL,
	IdUsuarioContaSistema int NULL,
	DtInclusao datetime NOT NULL,
	CONSTRAINT PK_PRODUTOTAG PRIMARY KEY (Id),
	CONSTRAINT FK_PRODUTOT_REFERENCE_PROD885 FOREIGN KEY (IdProduto) REFERENCES SuperCRMDB.dbo.Produto(Id) ON DELETE CASCADE,
	CONSTRAINT FK_PRODUTOT_REFERENCE_TAG896 FOREIGN KEY (IdTag) REFERENCES SuperCRMDB.dbo.Tag(Id) ON DELETE CASCADE,
	CONSTRAINT FK_PRODUTOT_REFERENCE_USUA7444 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id) ON DELETE CASCADE
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDX1 ON dbo.ProdutoTag (  IdTag ASC  , IdProduto ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX IDXGUID ON dbo.ProdutoTag (  IdGuid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.UsuarioContaSistemaPresenca definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.UsuarioContaSistemaPresenca;

CREATE TABLE SuperCRMDB.dbo.UsuarioContaSistemaPresenca (
	IdContaSistema int NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	IdGuidContaSistema char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdGuidUsuarioContaSistema char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInicio datetime NOT NULL,
	DtUltimaConfirmacao datetime NOT NULL,
	DtFim datetime NULL,
	CONSTRAINT PK_USUARIOCONTASISTEMAPRESENCA PRIMARY KEY (IdContaSistema,IdUsuarioContaSistema),
	CONSTRAINT FK_USUARIOC_REFERENCE_CON129 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id) ON DELETE CASCADE,
	CONSTRAINT FK_USUARIOC_REFERENCE_USU4575 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id) ON DELETE CASCADE
);
 CREATE NONCLUSTERED INDEX idxDtFim ON dbo.UsuarioContaSistemaPresenca (  DtFim ASC  )  
	 INCLUDE ( IdGuidContaSistema , IdGuidUsuarioContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdGuidContaSistema ON dbo.UsuarioContaSistemaPresenca (  IdGuidContaSistema ASC  , IdGuidUsuarioContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuidUsuarioContaSistema ON dbo.UsuarioContaSistemaPresenca (  IdGuidUsuarioContaSistema ASC  , IdGuidContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxUniqueIdContaSistema ON dbo.UsuarioContaSistemaPresenca (  IdContaSistema ASC  , IdUsuarioContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.RemessaLog definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.RemessaLog;

CREATE TABLE SuperCRMDB.dbo.RemessaLog (
	Id int IDENTITY(1,1) NOT NULL,
	IdRemessa int NOT NULL,
	Tipo varchar(50) COLLATE Latin1_General_CI_AI NULL,
	LogTipo varchar(500) COLLATE Latin1_General_CI_AI NOT NULL,
	Log varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	ObjTipo varchar(500) COLLATE Latin1_General_CI_AI NULL,
	Obj varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_REMESSALOG PRIMARY KEY (Id),
	CONSTRAINT FK_REMESSAL_REFERENCE_REM733 FOREIGN KEY (IdRemessa) REFERENCES SuperCRMDB.dbo.Remessa(Id) ON DELETE CASCADE
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.RemessaLog (  IdGuid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxRemessa ON dbo.RemessaLog (  IdRemessa ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.LogAcoes definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.LogAcoes;

CREATE TABLE SuperCRMDB.dbo.LogAcoes (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NULL,
	IdUsuarioContaSistemaExecutou int NULL,
	Tipo varchar(300) COLLATE Latin1_General_CI_AI NOT NULL,
	TipoSub varchar(300) COLLATE Latin1_General_CI_AI NOT NULL,
	Texto varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	ValueOld varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	ValueNew varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	NomeMethod varchar(1000) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime NOT NULL,
	TabelaBD varchar(300) COLLATE Latin1_General_CI_AI NULL,
	TabelaBDChave int NULL,
	EnviarEmailAdministradorAnapro bit DEFAULT 0 NOT NULL,
	IdUsuarioContaSistemaImpactou int NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	IP varchar(50) COLLATE Latin1_General_CI_AI NULL,
	UsuarioSimulandoIdGuidCorrex char(36) COLLATE Latin1_General_CI_AI NULL,
	ObjJson varchar(800) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_LOGACOES PRIMARY KEY (Id),
	CONSTRAINT FK_LOGACOES_REFERENCE_CON5698 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id) ON DELETE CASCADE,
	CONSTRAINT FK_LOGACOES_REFERENCE_U75321 FOREIGN KEY (IdUsuarioContaSistemaExecutou) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id) ON DELETE CASCADE,
	CONSTRAINT FK_USUARIOC_REFERENCE_5A562 FOREIGN KEY (IdUsuarioContaSistemaImpactou) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX idx2DtInclusao ON dbo.LogAcoes (  DtInclusao ASC  , IdContaSistema ASC  )  
	 INCLUDE ( IdUsuarioContaSistemaExecutou , IdUsuarioContaSistemaImpactou , Tipo , TipoSub ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2IdUsuarioContaSistemaExecutou ON dbo.LogAcoes (  IdUsuarioContaSistemaExecutou ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , IdUsuarioContaSistemaImpactou , Tipo , TipoSub ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2IdUsuarioContaSistemaImpactou ON dbo.LogAcoes (  IdUsuarioContaSistemaImpactou ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , IdUsuarioContaSistemaExecutou , Tipo , TipoSub ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2Tipo ON dbo.LogAcoes (  Tipo ASC  , IdContaSistema ASC  , TipoSub ASC  , DtInclusao ASC  )  
	 INCLUDE ( IdUsuarioContaSistemaExecutou , IdUsuarioContaSistemaImpactou ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxContaSistema ON dbo.LogAcoes (  IdContaSistema ASC  , DtInclusao ASC  )  
	 INCLUDE ( Id , IdUsuarioContaSistemaExecutou , IdUsuarioContaSistemaImpactou , Tipo , TipoSub ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.LogAcoes (  IdGuid ASC  )  
	 INCLUDE ( IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 80   ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.PessoaProspectImportacaoTemp definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PessoaProspectImportacaoTemp;

CREATE TABLE SuperCRMDB.dbo.PessoaProspectImportacaoTemp (
	Id int IDENTITY(1,1) NOT NULL,
	IdPessoaProspectImportacao int NOT NULL,
	Status varchar(30) COLLATE Latin1_General_CI_AI NOT NULL,
	DtUltimoStatus datetime NULL,
	ObjTipo varchar(30) COLLATE Latin1_General_CI_AI NOT NULL,
	Obj varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	QtdTentativa int DEFAULT 0 NOT NULL,
	SysValido bit DEFAULT 0 NOT NULL,
	SysValidoEndereco bit DEFAULT 0 NOT NULL,
	SysErroColunas varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	SysErroObs varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	ErroInternoObs varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	NovoProspect bit DEFAULT 0 NOT NULL,
	CONSTRAINT PK_PESSOAPROSPECTIMPORTACAOTEM PRIMARY KEY (Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_PESS457 FOREIGN KEY (IdPessoaProspectImportacao) REFERENCES SuperCRMDB.dbo.PessoaProspectImportacao(Id) ON DELETE CASCADE
);
 CREATE NONCLUSTERED INDEX idxIdPessoaProspectImportacao ON dbo.PessoaProspectImportacaoTemp (  IdPessoaProspectImportacao ASC  , Status ASC  , SysValido ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX nci_wi_PessoaProspectImportacaoTemp_2DF03E5FF7CBEC080CB394C30AA779F7 ON dbo.PessoaProspectImportacaoTemp (  IdPessoaProspectImportacao ASC  )  
	 INCLUDE ( DtUltimoStatus , ErroInternoObs , NovoProspect , Obj , ObjTipo , QtdTentativa , Status , SysErroColunas , SysErroObs , SysValido , SysValidoEndereco ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.PessoaProspect definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PessoaProspect;

CREATE TABLE SuperCRMDB.dbo.PessoaProspect (
	Id int NOT NULL,
	IdCanalOrigem int NULL,
	Nome varchar(300) COLLATE Latin1_General_CI_AI NOT NULL,
	Codigo varchar(50) COLLATE Latin1_General_CI_AI NULL,
	Sexo char(1) COLLATE Latin1_General_CI_AI NULL,
	DtNascimento datetime NULL,
	IdPessoaProfissao int NULL,
	IdContaSistema int NOT NULL,
	versao timestamp NOT NULL,
	DtAnonimizacao datetime NULL,
	IdUsuarioContaSistemaAnonimizado int NULL,
	RegistroStatus char(3) COLLATE Latin1_General_CI_AI NULL,
	RegistroStatusIdUsuarioContaSistema int NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NULL,
	dtInclusao datetime DEFAULT NULL NOT NULL,
	CONSTRAINT PK_PESSOAPROSPECT PRIMARY KEY (Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_CANAL FOREIGN KEY (IdCanalOrigem) REFERENCES SuperCRMDB.dbo.Canal(Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_CONT588 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_PESSO78 FOREIGN KEY (IdPessoaProfissao) REFERENCES SuperCRMDB.dbo.PessoaProfissao(Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_SUPER129 FOREIGN KEY (Id) REFERENCES SuperCRMDB.dbo.SuperEntidade(Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_USU4588 FOREIGN KEY (IdUsuarioContaSistemaAnonimizado) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX idxCodigo ON dbo.PessoaProspect (  Codigo ASC  , Nome ASC  )  
	 INCLUDE ( Id , IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.PessoaProspect (  IdContaSistema ASC  , Id ASC  )  
	 INCLUDE ( Codigo , Nome ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdUsuarioContaSistemaAnonimizado ON dbo.PessoaProspect (  IdUsuarioContaSistemaAnonimizado ASC  )  
	 INCLUDE ( DtAnonimizacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxNome ON dbo.PessoaProspect (  Nome ASC  , Codigo ASC  )  
	 INCLUDE ( Id , IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxNome2 ON dbo.PessoaProspect (  IdContaSistema ASC  , Nome ASC  , Codigo ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxRegistroStatus ON dbo.PessoaProspect (  RegistroStatus ASC  )  
	 INCLUDE ( IdContaSistema , RegistroStatusIdUsuarioContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxVersao ON dbo.PessoaProspect (  versao ASC  , Id ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Alarme definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Alarme;

CREATE TABLE SuperCRMDB.dbo.Alarme (
	Id int IDENTITY(1,1) NOT NULL,
	[Data] datetime NOT NULL,
	DataUltimoStatus datetime NOT NULL,
	Tipo varchar(15) COLLATE Latin1_General_CI_AI NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	IdUsuarioContaSistemaUltimoStatus int NULL,
	Realizado bit DEFAULT 0 NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	DtAtualizacaoAuto datetime DEFAULT [dbo].[GetDateCustom]() NULL,
	IdSuperEntidade int NOT NULL,
	DtInclusao datetime DEFAULT [dbo].[GetDateCustom]() NOT NULL,
	versao timestamp NOT NULL,
	IdContaSistema int NOT NULL,
	CONSTRAINT PK_ALARME PRIMARY KEY (Id),
	CONSTRAINT FK_ALARME_REFERENCE_SUPER478 FOREIGN KEY (IdSuperEntidade) REFERENCES SuperCRMDB.dbo.SuperEntidade(Id),
	CONSTRAINT FK_ALARME_REFERENCE_USUAR455 FOREIGN KEY (IdUsuarioContaSistemaUltimoStatus) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX idxDtAtualizacaoAuto ON dbo.Alarme (  DtAtualizacaoAuto ASC  )  
	 INCLUDE ( Id , IdSuperEntidade ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.Alarme (  IdContaSistema ASC  , Data ASC  )  
	 INCLUDE ( IdSuperEntidade , Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.Alarme (  IdGuid ASC  )  
	 INCLUDE ( Data , Id , IdSuperEntidade , Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdSuperEntidade ON dbo.Alarme (  IdSuperEntidade ASC  , Data ASC  , Status ASC  )  
	 INCLUDE ( DataUltimoStatus , Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdSuperEntidade2 ON dbo.Alarme (  IdSuperEntidade ASC  , DataUltimoStatus DESC  , Status ASC  )  
	 INCLUDE ( Data , Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxStatus ON dbo.Alarme (  Status ASC  , IdSuperEntidade ASC  , Data ASC  )  
	 INCLUDE ( DataUltimoStatus , Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX nci_wi_Alarme_733F3DA78C252149B385F0B4752A4969 ON dbo.Alarme (  IdContaSistema ASC  , Status ASC  , Data ASC  )  
	 INCLUDE ( IdSuperEntidade ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.TabelaoAlarme definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.TabelaoAlarme;

CREATE TABLE SuperCRMDB.dbo.TabelaoAlarme (
	AlarmeId int NOT NULL,
	AlarmeIdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	AlarmeData datetime NOT NULL,
	AlarmeStatus char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	ContaSistemaId int NOT NULL,
	UsuarioContaSistemaId int NULL,
	PessoaNome varchar(500) COLLATE Latin1_General_CI_AI NULL,
	PessoaProspectNome varchar(500) COLLATE Latin1_General_CI_AI NOT NULL,
	AtendimentoId int NOT NULL,
	UsuarioContaSistemaIdGuid char(36) COLLATE Latin1_General_CI_AI NULL,
	UsuarioCorrexIdGuid char(36) COLLATE Latin1_General_CI_AI NULL,
	AlarmeDtUltimaInteracao datetime NULL,
	DtAtualizacaoAuto datetime NULL,
	InteracaoId int NOT NULL,
	InteracaoIdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	InteracaoDtInclusao datetime NOT NULL,
	InteracaoTexto varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	InteracaoInteracaotipo varchar(200) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_TABELAOALARME PRIMARY KEY (AlarmeId),
	CONSTRAINT FK_TABELAOA_REFERENCE_ALARME FOREIGN KEY (AlarmeId) REFERENCES SuperCRMDB.dbo.Alarme(Id) ON DELETE CASCADE
);
 CREATE NONCLUSTERED INDEX idxAtendimentoId ON dbo.TabelaoAlarme (  AtendimentoId ASC  , AlarmeStatus ASC  )  
	 INCLUDE ( AlarmeData , AlarmeId , ContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxContaSistemaId ON dbo.TabelaoAlarme (  ContaSistemaId ASC  , AtendimentoId ASC  )  
	 INCLUDE ( AlarmeData , AlarmeStatus ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxDtAlarme ON dbo.TabelaoAlarme (  AlarmeData ASC  , ContaSistemaId ASC  , AtendimentoId ASC  )  
	 INCLUDE ( AlarmeId , AlarmeStatus ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.PessoaProspectTelefone definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PessoaProspectTelefone;

CREATE TABLE SuperCRMDB.dbo.PessoaProspectTelefone (
	Id int IDENTITY(1,1) NOT NULL,
	IdPessoaProspect int NOT NULL,
	Tipo char(4) COLLATE Latin1_General_CI_AI NOT NULL,
	DDD char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	Telefone varchar(10) COLLATE Latin1_General_CI_AI NOT NULL,
	Ramal varchar(20) COLLATE Latin1_General_CI_AI NULL,
	Obs varchar(400) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	Valido bit DEFAULT 1 NOT NULL,
	Verificado bit DEFAULT 0 NOT NULL,
	IdUsuarioContaSistema int NULL,
	CONSTRAINT PK_PESSOAPROSPECTTELEFONE PRIMARY KEY (Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_PES4588 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_PESSOAP1 FOREIGN KEY (IdPessoaProspect) REFERENCES SuperCRMDB.dbo.PessoaProspect(Id) ON DELETE CASCADE ON UPDATE CASCADE
);
 CREATE NONCLUSTERED INDEX idxIdPessoaProspect ON dbo.PessoaProspectTelefone (  IdPessoaProspect ASC  , Telefone ASC  )  
	 INCLUDE ( DDD ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxTelefone ON dbo.PessoaProspectTelefone (  Telefone ASC  , DDD ASC  )  
	 INCLUDE ( IdPessoaProspect ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxUnique ON dbo.PessoaProspectTelefone (  IdGuid ASC  )  
	 INCLUDE ( Id , IdPessoaProspect ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.PessoaProspectEmail definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PessoaProspectEmail;

CREATE TABLE SuperCRMDB.dbo.PessoaProspectEmail (
	Id int IDENTITY(1,1) NOT NULL,
	IdPessoaProspect int NOT NULL,
	Tipo varchar(15) COLLATE Latin1_General_CI_AI NOT NULL,
	Email varchar(500) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	Obs varchar(400) COLLATE Latin1_General_CI_AI NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	Valido bit DEFAULT 1 NOT NULL,
	Verificado bit DEFAULT 0 NOT NULL,
	IdUsuarioContaSistema int NULL,
	CONSTRAINT PK_PESSOAPROSPECTEMAIL PRIMARY KEY (Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_PESSOAP3 FOREIGN KEY (IdPessoaProspect) REFERENCES SuperCRMDB.dbo.PessoaProspect(Id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT FK_PESSOAPR_REFERENCE_USU784 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX idxEmail ON dbo.PessoaProspectEmail (  Email ASC  , IdPessoaProspect ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.PessoaProspectEmail (  IdGuid ASC  )  
	 INCLUDE ( Id , IdPessoaProspect ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdPessoaProspect ON dbo.PessoaProspectEmail (  IdPessoaProspect ASC  , Email ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.PessoaProspectTag definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PessoaProspectTag;

CREATE TABLE SuperCRMDB.dbo.PessoaProspectTag (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	IdTag int NOT NULL,
	IdPessoaProspect int NOT NULL,
	IdUsuarioContaSistema int NULL,
	DtInclusao datetime NOT NULL,
	TipoOrigem varchar(300) COLLATE Latin1_General_CI_AI NOT NULL,
	Obs varchar(1000) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_PESSOAPROSPECTTAG PRIMARY KEY (Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_PESAPR879 FOREIGN KEY (IdPessoaProspect) REFERENCES SuperCRMDB.dbo.PessoaProspect(Id) ON DELETE CASCADE,
	CONSTRAINT FK_PESSOAPR_REFERENCE_TAG489 FOREIGN KEY (IdTag) REFERENCES SuperCRMDB.dbo.Tag(Id) ON DELETE CASCADE,
	CONSTRAINT FK_PESSOAPR_REFERENCE_USUAR365 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id) ON DELETE CASCADE
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDXGUID ON dbo.PessoaProspectTag (  IdGuid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdPessoaProspect ON dbo.PessoaProspectTag (  IdPessoaProspect ASC  , IdTag ASC  )  
	 INCLUDE ( Id , IdGuid ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdTag ON dbo.PessoaProspectTag (  IdTag ASC  , IdPessoaProspect ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.PendenciaProcessamento definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PendenciaProcessamento;

CREATE TABLE SuperCRMDB.dbo.PendenciaProcessamento (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdContaSistema int NULL,
	IdUsuarioContaSistema int NULL,
	IdGuidContaSistema char(36) COLLATE Latin1_General_CI_AI NULL,
	IdGuidUsuarioContaSistema char(36) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime NOT NULL,
	DtValidadeInicioProcessamento datetime NOT NULL,
	DtUltimaAtualizacao datetime NULL,
	DtProcessado datetime NULL,
	DtAvisado datetime NULL,
	QtdAtualizacao int NOT NULL,
	Status varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	Origem varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	PreProcessado bit DEFAULT 0 NOT NULL,
	Processado bit NOT NULL,
	Finalizado bit NOT NULL,
	Tipo varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	QtdTentativaProcessamento int DEFAULT 0 NOT NULL,
	AvisarAdmOnError bit DEFAULT 0 NOT NULL,
	PendenciaHashSHA1 char(40) COLLATE Latin1_General_CI_AI NOT NULL,
	ObjTipo varchar(1000) COLLATE Latin1_General_CI_AI NOT NULL,
	ObjSerializado varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	DtPreProcessado datetime NULL,
	CONSTRAINT PK_PENDENCIAPROCESSAMENTO PRIMARY KEY (Id),
	CONSTRAINT FK_PENDENCI_REFERENCE_CONT253 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id) ON DELETE CASCADE,
	CONSTRAINT FK_PENDENCI_REFERENCE_USU44230 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id) ON DELETE CASCADE
);
 CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.PendenciaProcessamento (  IdContaSistema ASC  , IdUsuarioContaSistema ASC  , Status ASC  , DtPreProcessado ASC  )  
	 INCLUDE ( Tipo ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.PendenciaProcessamento (  IdGuid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxPendenciaHashSHA1 ON dbo.PendenciaProcessamento (  PendenciaHashSHA1 ASC  , Finalizado ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxPreProcessado ON dbo.PendenciaProcessamento (  PreProcessado ASC  , Processado ASC  , Status ASC  )  
	 INCLUDE ( DtPreProcessado , DtProcessado , Finalizado , IdUsuarioContaSistema , QtdAtualizacao , QtdTentativaProcessamento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxStatus ON dbo.PendenciaProcessamento (  Status ASC  , PreProcessado ASC  , DtInclusao ASC  , DtValidadeInicioProcessamento ASC  )  
	 INCLUDE ( IdContaSistema , IdGuidContaSistema , IdGuidUsuarioContaSistema , IdUsuarioContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxStatus2 ON dbo.PendenciaProcessamento (  Status ASC  , PreProcessado ASC  , Processado ASC  , Finalizado ASC  )  
	 INCLUDE ( DtPreProcessado , IdContaSistema , IdGuidContaSistema , IdGuidUsuarioContaSistema , IdUsuarioContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.PessoaProspectPrefereciaFidelizacao definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PessoaProspectPrefereciaFidelizacao;

CREATE TABLE SuperCRMDB.dbo.PessoaProspectPrefereciaFidelizacao (
	Id int IDENTITY(1,1) NOT NULL,
	IdPessoaProspect int NOT NULL,
	IdPessoaProspectImportacao int NOT NULL,
	IdCampanha int NULL,
	IdUsuarioContaSistema int NOT NULL,
	DtInclusao datetime NOT NULL,
	Obs varchar(1500) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_PESSOAPROSPECTPREFERECIAFID PRIMARY KEY (Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_PESS325 FOREIGN KEY (IdPessoaProspectImportacao) REFERENCES SuperCRMDB.dbo.PessoaProspectImportacao(Id) ON DELETE CASCADE,
	CONSTRAINT FK_PESSOAPR_REFERENCE_PESS45 FOREIGN KEY (IdPessoaProspect) REFERENCES SuperCRMDB.dbo.PessoaProspect(Id) ON DELETE CASCADE
);
 CREATE NONCLUSTERED INDEX idxIdPessoaProspect ON dbo.PessoaProspectPrefereciaFidelizacao (  IdPessoaProspect ASC  , DtInclusao ASC  )  
	 INCLUDE ( Id , IdPessoaProspectImportacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdPessoaProspectImportacao ON dbo.PessoaProspectPrefereciaFidelizacao (  IdPessoaProspectImportacao ASC  , DtInclusao ASC  )  
	 INCLUDE ( Id , IdPessoaProspect ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Midia definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Midia;

CREATE TABLE SuperCRMDB.dbo.Midia (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NOT NULL,
	Nome varchar(500) COLLATE Latin1_General_CI_AI NULL,
	Obs varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	AutoInclusao int DEFAULT 0 NOT NULL,
	DtInclusao datetime NOT NULL,
	IdMidiaTipo int NULL,
	GUID char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	Publica bit DEFAULT 0 NOT NULL,
	IdIntegradoraExterna int NULL,
	DtAtualizacao datetime NULL,
	versao timestamp NOT NULL,
	CONSTRAINT PK_MIDIA PRIMARY KEY (Id),
	CONSTRAINT FK_MIDIA_REFERENCE_CONTASIS FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id),
	CONSTRAINT FK_MIDIA_REFERENCE_INTEG457 FOREIGN KEY (IdIntegradoraExterna) REFERENCES SuperCRMDB.dbo.IntegradoraExterna(Id) ON DELETE SET NULL,
	CONSTRAINT FK_MIDIA_REFERENCE_MIDI333 FOREIGN KEY (IdMidiaTipo) REFERENCES SuperCRMDB.dbo.MidiaTipo(Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.Midia (  GUID ASC  )  
	 INCLUDE ( IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.Midia (  IdContaSistema ASC  , Status ASC  , Publica ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdIntegradoraExterna ON dbo.Midia (  IdIntegradoraExterna ASC  )  
	 INCLUDE ( Id , IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxNome ON dbo.Midia (  Nome ASC  , IdContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxVersao ON dbo.Midia (  versao ASC  , Id ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX nci_wi_Midia_BF430F456F4A2A1A9A78D44E3B12F43C ON dbo.Midia (  IdContaSistema ASC  , Publica ASC  , Status ASC  )  
	 INCLUDE ( AutoInclusao , DtAtualizacao , DtInclusao , GUID , IdIntegradoraExterna , IdMidiaTipo , Nome , Obs , versao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal;

CREATE TABLE SuperCRMDB.dbo.UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal (
	Id int IDENTITY(1,1) NOT NULL,
	IdCampanhaGrupo int NOT NULL,
	IdPlantaoHorario int NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	IdCampanhaCanal int NOT NULL,
	DtInclusao datetime NOT NULL,
	DtInteracaoFila datetime NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	Prioridade int DEFAULT 999999 NOT NULL,
	Obs varchar(300) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_USUARIOCONTASISTEMACAMPANHA PRIMARY KEY (Id),
	CONSTRAINT FK_USUARIOC_REFERENCE_CAMPANH15 FOREIGN KEY (IdCampanhaCanal) REFERENCES SuperCRMDB.dbo.CampanhaCanal(Id) ON DELETE CASCADE,
	CONSTRAINT FK_USUARIOC_REFERENCE_CAMPANHA FOREIGN KEY (IdCampanhaGrupo) REFERENCES SuperCRMDB.dbo.CampanhaGrupo(Id) ON DELETE CASCADE,
	CONSTRAINT FK_USUARIOC_REFERENCE_PLANTAOH FOREIGN KEY (IdPlantaoHorario) REFERENCES SuperCRMDB.dbo.PlantaoHorario(Id) ON DELETE CASCADE,
	CONSTRAINT FK_USUARIOC_REFERENCE_USUARIOC FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id) ON DELETE CASCADE
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdCampanhaCanalUnique ON dbo.UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal (  IdCampanhaCanal ASC  , IdPlantaoHorario ASC  , IdUsuarioContaSistema ASC  , IdCampanhaGrupo ASC  )  
	 INCLUDE ( DtInclusao , DtInteracaoFila , Obs , Prioridade ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdUsuarioContaSistema ON dbo.UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal (  IdUsuarioContaSistema ASC  , Status ASC  )  
	 INCLUDE ( Id , IdCampanhaCanal , IdCampanhaGrupo , IdPlantaoHorario ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX nci_wi_UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal_3EB809E1F823B6A07A913DA58C5916A4 ON dbo.UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal (  IdCampanhaGrupo ASC  , IdUsuarioContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracaoFila , IdCampanhaCanal , IdPlantaoHorario , Obs , Prioridade , Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.PessoaProspectEndereco definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PessoaProspectEndereco;

CREATE TABLE SuperCRMDB.dbo.PessoaProspectEndereco (
	Id int IDENTITY(1,1) NOT NULL,
	IdPessoaProspect int NOT NULL,
	UF char(2) COLLATE Latin1_General_CI_AI NULL,
	IdCidade int NULL,
	IdBairro int NULL,
	Tipo char(3) COLLATE Latin1_General_CI_AI NOT NULL,
	Logradouro varchar(500) COLLATE Latin1_General_CI_AI NULL,
	Complemento varchar(500) COLLATE Latin1_General_CI_AI NULL,
	Numero varchar(30) COLLATE Latin1_General_CI_AI NULL,
	CEP varchar(10) COLLATE Latin1_General_CI_AI NULL,
	Obs varchar(500) COLLATE Latin1_General_CI_AI NULL,
	CEPNumber int NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	CONSTRAINT PK_PESSOAPROSPECTENDERECO PRIMARY KEY (Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_DBL5622 FOREIGN KEY (IdCidade) REFERENCES SuperCRMDB.dbo.DbLocalidadeCidade(Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_DBL5633 FOREIGN KEY (IdBairro) REFERENCES SuperCRMDB.dbo.DbLocalidadeBairro(Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_PESSOA89 FOREIGN KEY (IdPessoaProspect) REFERENCES SuperCRMDB.dbo.PessoaProspect(Id) ON DELETE CASCADE ON UPDATE CASCADE
);
 CREATE NONCLUSTERED INDEX IDXPESSOAPROSPECT ON dbo.PessoaProspectEndereco (  IdPessoaProspect ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx1 ON dbo.PessoaProspectEndereco (  IdPessoaProspect ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxUnique ON dbo.PessoaProspectEndereco (  IdGuid ASC  )  
	 INCLUDE ( Id , IdPessoaProspect ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.RemessaCustom definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.RemessaCustom;

CREATE TABLE SuperCRMDB.dbo.RemessaCustom (
	IdRemessa int NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	Tipo varchar(30) COLLATE Latin1_General_CI_AI NOT NULL,
	ObjTipo varchar(500) COLLATE Latin1_General_CI_AI NOT NULL,
	Obj varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_REMESSACUSTOM PRIMARY KEY (IdRemessa),
	CONSTRAINT FK_REMESSAC_REFERENCE_REM785 FOREIGN KEY (IdRemessa) REFERENCES SuperCRMDB.dbo.Remessa(Id) ON DELETE CASCADE
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.RemessaCustom (  IdGuid ASC  )  
	 INCLUDE ( IdRemessa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxRemessaUnique ON dbo.RemessaCustom (  IdRemessa ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.RemessaTotalVoice definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.RemessaTotalVoice;

CREATE TABLE SuperCRMDB.dbo.RemessaTotalVoice (
	IdRemessa int NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	CallerId int NOT NULL,
	DtInclusao datetime NOT NULL,
	DtCriacao datetime NOT NULL,
	Status varchar(35) COLLATE Latin1_General_CI_AI NOT NULL,
	DtStatus datetime NOT NULL,
	QtdStatusProcessamento int DEFAULT 0 NOT NULL,
	StatusProcessamento varchar(35) COLLATE Latin1_General_CI_AI NOT NULL,
	DtStatusProcessamento datetime NOT NULL,
	Ativa bit NOT NULL,
	ClientId int NULL,
	ContaId int NULL,
	RamalIdOrigem int NULL,
	Tags varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	OrigemDtInicio datetime NULL,
	OrigemNumero varchar(15) COLLATE Latin1_General_CI_AI NULL,
	OrigemTipo varchar(50) COLLATE Latin1_General_CI_AI NULL,
	OrigemStatus varchar(50) COLLATE Latin1_General_CI_AI NULL,
	OrigemDuracaoSegundos int NULL,
	OrigemDuracaoCobradaSegundos int NULL,
	OrigemDuracaoFaladaSegundos int NULL,
	DestinoDtInicio datetime NULL,
	DestinoNumero varchar(15) COLLATE Latin1_General_CI_AI NULL,
	DestinoTipo varchar(50) COLLATE Latin1_General_CI_AI NULL,
	DestinoStatus varchar(50) COLLATE Latin1_General_CI_AI NULL,
	DestinoDuracaoSegundos int NULL,
	DestinoDuracaoCobradaSegundos int NULL,
	DestinoDuracaoFaladaSegundos int NULL,
	MostrarNumeroOrigem bit NOT NULL,
	MostrarNumeroDestino bit NOT NULL,
	OrigemCusto decimal(18,3) NULL,
	DestinoCusto decimal(18,3) NULL,
	GravacaoLink varchar(1000) COLLATE Latin1_General_CI_AI NULL,
	Gravada bit NOT NULL,
	Duracao time NULL,
	CustoTotal decimal(18,3) NOT NULL,
	DtInicio datetime NULL,
	DtFim datetime NULL,
	CallerIdParent int NULL,
	DestinoOriginalNumero varchar(15) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_REMESSATOTALVOICE PRIMARY KEY (IdRemessa),
	CONSTRAINT FK_REMESSAT_REFERENCE_REME478 FOREIGN KEY (IdRemessa) REFERENCES SuperCRMDB.dbo.RemessaCustom(IdRemessa) ON DELETE CASCADE
);
 CREATE NONCLUSTERED INDEX idx1 ON dbo.RemessaTotalVoice (  StatusProcessamento ASC  , Status ASC  , DtStatusProcessamento ASC  )  
	 INCLUDE ( DtStatus , IdRemessa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxCallerIdUnique ON dbo.RemessaTotalVoice (  CallerId ASC  )  
	 INCLUDE ( IdRemessa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuidUnique ON dbo.RemessaTotalVoice (  IdGuid ASC  )  
	 INCLUDE ( IdRemessa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxNumDestino ON dbo.RemessaTotalVoice (  DestinoNumero ASC  )  
	 INCLUDE ( IdRemessa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxNumOrigem ON dbo.RemessaTotalVoice (  OrigemNumero ASC  )  
	 INCLUDE ( IdRemessa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.PessoaProspectDocumento definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PessoaProspectDocumento;

CREATE TABLE SuperCRMDB.dbo.PessoaProspectDocumento (
	Id int IDENTITY(1,1) NOT NULL,
	IdPessoaProspect int NOT NULL,
	TipoDoc varchar(10) COLLATE Latin1_General_CI_AI NOT NULL,
	Doc varchar(30) COLLATE Latin1_General_CI_AI NOT NULL,
	DocOrgaoExp varchar(50) COLLATE Latin1_General_CI_AI NULL,
	DocDtExpedicao date NULL,
	DtInclusao datetime NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	IdUsuarioContaSistema int NULL,
	CONSTRAINT PK_PESSOAPROSPECTDOCUMENTO PRIMARY KEY (Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_PESSOA5 FOREIGN KEY (IdPessoaProspect) REFERENCES SuperCRMDB.dbo.PessoaProspect(Id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT FK_PESSOAPR_REFERENCE_USUA411 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX IDX1 ON dbo.PessoaProspectDocumento (  IdPessoaProspect ASC  , Doc ASC  , TipoDoc ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2 ON dbo.PessoaProspectDocumento (  TipoDoc ASC  , Doc ASC  , IdPessoaProspect ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx3 ON dbo.PessoaProspectDocumento (  Doc ASC  , TipoDoc ASC  , IdPessoaProspect ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx4 ON dbo.PessoaProspectDocumento (  IdPessoaProspect ASC  , TipoDoc ASC  )  
	 INCLUDE ( Doc , Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxUnique ON dbo.PessoaProspectDocumento (  IdGuid ASC  )  
	 INCLUDE ( Id , IdPessoaProspect ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.GrupoHierarquiaUsuarioContaSistema definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.GrupoHierarquiaUsuarioContaSistema;

CREATE TABLE SuperCRMDB.dbo.GrupoHierarquiaUsuarioContaSistema (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	IdGrupo int NOT NULL,
	CONSTRAINT PK_GRUPOHIERARQUIAUSUARIOCONTA PRIMARY KEY (Id),
	CONSTRAINT FK_GRUPOHIE_REFERENCE_G4545 FOREIGN KEY (IdGrupo) REFERENCES SuperCRMDB.dbo.Grupo(Id) ON DELETE CASCADE
);
 CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.GrupoHierarquiaUsuarioContaSistema (  IdContaSistema ASC  , IdUsuarioContaSistema ASC  )  
	 INCLUDE ( IdGrupo ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdGrupo ON dbo.GrupoHierarquiaUsuarioContaSistema (  IdGrupo ASC  , IdUsuarioContaSistema ASC  )  
	 INCLUDE ( Id , IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdUsuarioContaSistema ON dbo.GrupoHierarquiaUsuarioContaSistema (  IdUsuarioContaSistema ASC  , IdGrupo ASC  , IdContaSistema ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.PessoaProspectOrigem definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PessoaProspectOrigem;

CREATE TABLE SuperCRMDB.dbo.PessoaProspectOrigem (
	Id int IDENTITY(1,1) NOT NULL,
	IdPessoaProspectImportacao int NULL,
	Nome varchar(300) COLLATE Latin1_General_CI_AI NOT NULL,
	Obs varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime NOT NULL,
	Tipo varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	idContaSistema int NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	CONSTRAINT PK_PESSOAPROSPECTORIGEM PRIMARY KEY (Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_CONTA100 FOREIGN KEY (idContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_PESSOAP32 FOREIGN KEY (IdPessoaProspectImportacao) REFERENCES SuperCRMDB.dbo.PessoaProspectImportacao(Id) ON DELETE CASCADE
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.PessoaProspectOrigem (  IdGuid ASC  )  
	 INCLUDE ( Id , idContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdPessoaProspectImportacao ON dbo.PessoaProspectOrigem (  IdPessoaProspectImportacao ASC  , idContaSistema ASC  )  
	 INCLUDE ( Nome ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxidContaSistema ON dbo.PessoaProspectOrigem (  idContaSistema ASC  , Nome ASC  )  
	 INCLUDE ( IdPessoaProspectImportacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.PoliticaDePrivacidadePessoaProspect definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PoliticaDePrivacidadePessoaProspect;

CREATE TABLE SuperCRMDB.dbo.PoliticaDePrivacidadePessoaProspect (
	Id int IDENTITY(1,1) NOT NULL,
	IdPoliticaDePrivacidade int NOT NULL,
	IdPessoaProspect int NOT NULL,
	DtInclusao datetime NOT NULL,
	ObjJson varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	ObjTipo varchar(500) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_POLITICADEPRIVACIDADEPESSOA PRIMARY KEY (Id),
	CONSTRAINT FK_POLITICA_REFERENCE_PESSOAPR FOREIGN KEY (IdPessoaProspect) REFERENCES SuperCRMDB.dbo.PessoaProspect(Id),
	CONSTRAINT FK_POLITICA_REFERENCE_PO785 FOREIGN KEY (IdPoliticaDePrivacidade) REFERENCES SuperCRMDB.dbo.PoliticaDePrivacidade(Id)
);
 CREATE NONCLUSTERED INDEX idxIdPessoaProspect ON dbo.PoliticaDePrivacidadePessoaProspect (  IdPessoaProspect ASC  , IdPoliticaDePrivacidade ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdPoliticaDePrivacidade ON dbo.PoliticaDePrivacidadePessoaProspect (  IdPoliticaDePrivacidade ASC  , IdPessoaProspect ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.UsuarioContaSistemaGrupo definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.UsuarioContaSistemaGrupo;

CREATE TABLE SuperCRMDB.dbo.UsuarioContaSistemaGrupo (
	Id int IDENTITY(1,1) NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	IdGrupo int NOT NULL,
	DtInicio datetime NOT NULL,
	DtFim datetime NULL,
	versao timestamp NOT NULL,
	CONSTRAINT PK_USUARIOCONTASISTEMAGRUPO PRIMARY KEY (Id),
	CONSTRAINT FK_USUARIOC_REFERENCE_GRUP23 FOREIGN KEY (IdGrupo) REFERENCES SuperCRMDB.dbo.Grupo(Id) ON DELETE CASCADE,
	CONSTRAINT FK_USUARIOC_REFERENCE_USUARIO1 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id),
	CONSTRAINT FK_USUARIOC_REFERENCE_USUARIO125 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id) ON DELETE CASCADE
);
 CREATE NONCLUSTERED INDEX IDXIDGRUPO ON dbo.UsuarioContaSistemaGrupo (  IdGrupo ASC  , DtFim ASC  )  
	 INCLUDE ( IdUsuarioContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX IDXIDUSUARIOCONTASISTEMA ON dbo.UsuarioContaSistemaGrupo (  IdUsuarioContaSistema ASC  , DtFim ASC  )  
	 INCLUDE ( IdGrupo ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Peca definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Peca;

CREATE TABLE SuperCRMDB.dbo.Peca (
	Id int IDENTITY(1,1) NOT NULL,
	IdMidia int NOT NULL,
	AutoInclusao bit DEFAULT 0 NOT NULL,
	Nome varchar(500) COLLATE Latin1_General_CI_AI NULL,
	Obs varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	Valor decimal(18,2) DEFAULT 0 NULL,
	GUID char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	versao timestamp NOT NULL,
	CONSTRAINT PK_PECA PRIMARY KEY (Id),
	CONSTRAINT FK_PECA_REFERENCE_MIDIA FOREIGN KEY (IdMidia) REFERENCES SuperCRMDB.dbo.Midia(Id)
);
 CREATE NONCLUSTERED INDEX idxGUID ON dbo.Peca (  GUID ASC  , IdMidia ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdMidia ON dbo.Peca (  IdMidia ASC  , Nome ASC  )  
	 INCLUDE ( Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxNome ON dbo.Peca (  Nome ASC  , IdMidia ASC  )  
	 INCLUDE ( Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxVersao ON dbo.Peca (  versao ASC  , Id ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.UsuarioContaSistemaGrupoAdm definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.UsuarioContaSistemaGrupoAdm;

CREATE TABLE SuperCRMDB.dbo.UsuarioContaSistemaGrupoAdm (
	Id int IDENTITY(1,1) NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	IdGrupo int NOT NULL,
	DtInicio datetime NOT NULL,
	DtFim datetime NULL,
	versao timestamp NOT NULL,
	CONSTRAINT PK_USUARIOCONTASISTEMAGRUPOADM PRIMARY KEY (Id),
	CONSTRAINT FK_USUARIOC_REFERENCE_GRUP24 FOREIGN KEY (IdGrupo) REFERENCES SuperCRMDB.dbo.Grupo(Id) ON DELETE CASCADE,
	CONSTRAINT FK_USUARIOC_REFERENCE_USUAR4545 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id) ON DELETE CASCADE
);
 CREATE NONCLUSTERED INDEX IDXGRUPO ON dbo.UsuarioContaSistemaGrupoAdm (  IdGrupo ASC  , DtFim ASC  )  
	 INCLUDE ( IdUsuarioContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX IDXIDUSUARIOCONTASISTEMA_ ON dbo.UsuarioContaSistemaGrupoAdm (  IdUsuarioContaSistema ASC  , DtFim ASC  )  
	 INCLUDE ( IdGrupo ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX nci_wi_UsuarioContaSistemaGrupoAdm_292B4E488FC576C4DFA3BE5EF943B18B ON dbo.UsuarioContaSistemaGrupoAdm (  DtFim ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.GrupoHierarquia definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.GrupoHierarquia;

CREATE TABLE SuperCRMDB.dbo.GrupoHierarquia (
	Id int IDENTITY(1,1) NOT NULL,
	IdGrupoSuperior int NOT NULL,
	IdGrupoInferior int NOT NULL,
	Nivel int DEFAULT 0 NOT NULL,
	Mostrar bit DEFAULT 1 NOT NULL,
	IdContaSistema int NOT NULL,
	CONSTRAINT PK_GRUPOHIERARQUIA PRIMARY KEY (Id),
	CONSTRAINT FK_GRUPOHIE_REFERENCE_GRUP50 FOREIGN KEY (IdGrupoSuperior) REFERENCES SuperCRMDB.dbo.Grupo(Id) ON DELETE CASCADE,
	CONSTRAINT FK_GRUPOHIE_REFERENCE_GRUP51 FOREIGN KEY (IdGrupoInferior) REFERENCES SuperCRMDB.dbo.Grupo(Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.GrupoHierarquia (  IdGrupoSuperior ASC  , IdGrupoInferior ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdGrupoInferior ON dbo.GrupoHierarquia (  IdGrupoInferior ASC  )  
	 INCLUDE ( IdGrupoSuperior ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.TopicoTag definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.TopicoTag;

CREATE TABLE SuperCRMDB.dbo.TopicoTag (
	Id int IDENTITY(1,1) NOT NULL,
	IdTag int NOT NULL,
	IdTopico int NOT NULL,
	DtInclusao datetime NOT NULL,
	CONSTRAINT PK_TOPICOTAG PRIMARY KEY (Id),
	CONSTRAINT FK_TOPICOTA_REFERENCE_T4545 FOREIGN KEY (IdTopico) REFERENCES SuperCRMDB.dbo.Topico(Id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT FK_TOPICOTA_REFERENCE_TAG896 FOREIGN KEY (IdTag) REFERENCES SuperCRMDB.dbo.Tag(Id) ON DELETE CASCADE ON UPDATE CASCADE
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.TopicoTag (  IdTag ASC  , IdTopico ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdTopico ON dbo.TopicoTag (  IdTopico ASC  )  
	 INCLUDE ( IdTag ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.TelefoniaDID definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.TelefoniaDID;

CREATE TABLE SuperCRMDB.dbo.TelefoniaDID (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdTelefoniaTransportadora int NOT NULL,
	IdCidade int NOT NULL,
	IdCampanha int NOT NULL,
	IdCanal int NOT NULL,
	IdMidia int NULL,
	IdPeca int NULL,
	IdProduto int NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	DDD char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	Numero varchar(9) COLLATE Latin1_General_CI_AI NOT NULL,
	Obs varchar(500) COLLATE Latin1_General_CI_AI NULL,
	TelMestreDDD char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	TelMestreNumero varchar(9) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_TELEFONIADID PRIMARY KEY (Id),
	CONSTRAINT FK_TELEFONI_REFERENCE_CAMP4587 FOREIGN KEY (IdCampanha) REFERENCES SuperCRMDB.dbo.Campanha(Id) ON DELETE CASCADE,
	CONSTRAINT FK_TELEFONI_REFERENCE_DBLOC125 FOREIGN KEY (IdCidade) REFERENCES SuperCRMDB.dbo.DbLocalidadeCidade(Id),
	CONSTRAINT FK_TELEFONI_REFERENCE_MIDIA FOREIGN KEY (IdMidia) REFERENCES SuperCRMDB.dbo.Midia(Id) ON DELETE SET NULL,
	CONSTRAINT FK_TELEFONI_REFERENCE_PROD321 FOREIGN KEY (IdProduto) REFERENCES SuperCRMDB.dbo.Produto(Id) ON DELETE SET NULL,
	CONSTRAINT FK_TELEFONI_REFERENCE_TELE452 FOREIGN KEY (IdTelefoniaTransportadora) REFERENCES SuperCRMDB.dbo.Telefonia(IdTransportadora) ON DELETE CASCADE,
	CONSTRAINT FK_TELEFONI_REFERE_CANAL457 FOREIGN KEY (IdCanal) REFERENCES SuperCRMDB.dbo.Canal(Id) ON DELETE CASCADE,
	CONSTRAINT FK_TELEFONI_REFER_PECA854 FOREIGN KEY (IdPeca) REFERENCES SuperCRMDB.dbo.Peca(Id) ON DELETE SET NULL
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxGuidUnique ON dbo.TelefoniaDID (  IdGuid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxNumero ON dbo.TelefoniaDID (  Numero ASC  , DDD ASC  )  
	 INCLUDE ( Id , IdTelefoniaTransportadora ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxTelefonia ON dbo.TelefoniaDID (  IdTelefoniaTransportadora ASC  )  
	 INCLUDE ( DDD , Numero ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.PessoaProspectProdutoInteresse definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PessoaProspectProdutoInteresse;

CREATE TABLE SuperCRMDB.dbo.PessoaProspectProdutoInteresse (
	Id int IDENTITY(1,1) NOT NULL,
	IdPessoaProspect int NOT NULL,
	IdUsuarioContaSistema int NULL,
	IdProduto int NOT NULL,
	DtInclusao datetime NOT NULL,
	Obs varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_PESSOAPROSPECTPRODUTOINTERE PRIMARY KEY (Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_PESSOAPR FOREIGN KEY (IdPessoaProspect) REFERENCES SuperCRMDB.dbo.PessoaProspect(Id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT FK_PESSOAPR_REFERENCE_PRODUTO FOREIGN KEY (IdProduto) REFERENCES SuperCRMDB.dbo.Produto(Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_USUARIO1 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);


-- SuperCRMDB.dbo.TagAtalho definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.TagAtalho;

CREATE TABLE SuperCRMDB.dbo.TagAtalho (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NOT NULL,
	Codigo varchar(200) COLLATE Latin1_General_CI_AI NOT NULL,
	Descricao varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	IdCampanha int NULL,
	IdCanal int NULL,
	IdProduto int NULL,
	IdPeca int NULL,
	IdMidia int NULL,
	Status char(2) COLLATE Latin1_General_CI_AI DEFAULT 'AT' NOT NULL,
	DtModificacao datetime NULL,
	CONSTRAINT PK_TAGATALHO PRIMARY KEY (Id),
	CONSTRAINT FK_TAGATALH_REFERENCE_CAMPANHA FOREIGN KEY (IdCampanha) REFERENCES SuperCRMDB.dbo.Campanha(Id),
	CONSTRAINT FK_TAGATALH_REFERENCE_CANAL FOREIGN KEY (IdCanal) REFERENCES SuperCRMDB.dbo.Canal(Id),
	CONSTRAINT FK_TAGATALH_REFERENCE_CONTASIS FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id),
	CONSTRAINT FK_TAGATALH_REFERENCE_MIDIA FOREIGN KEY (IdMidia) REFERENCES SuperCRMDB.dbo.Midia(Id),
	CONSTRAINT FK_TAGATALH_REFERENCE_PECA FOREIGN KEY (IdPeca) REFERENCES SuperCRMDB.dbo.Peca(Id),
	CONSTRAINT FK_TAGATALH_REFERENCE_PRODUTO FOREIGN KEY (IdProduto) REFERENCES SuperCRMDB.dbo.Produto(Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDXCODIGOIDCONTASISTEMA ON dbo.TagAtalho (  IdContaSistema ASC  , Codigo ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.PessoaProspectPerfil definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PessoaProspectPerfil;

CREATE TABLE SuperCRMDB.dbo.PessoaProspectPerfil (
	Id int IDENTITY(1,1) NOT NULL,
	IdPessoaProspect int NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	IdPerfil int NOT NULL,
	DtInclusao datetime NOT NULL,
	Obs varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_PESSOAPROSPECTPERFIL PRIMARY KEY (Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_PERFIL FOREIGN KEY (IdPerfil) REFERENCES SuperCRMDB.dbo.Perfil(Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_PESSOAP2 FOREIGN KEY (IdPessoaProspect) REFERENCES SuperCRMDB.dbo.PessoaProspect(Id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT FK_PESSOAPR_REFERENCE_USUARIOC FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX nci_wi_PessoaProspectPerfil_21FC2186AD6A36EC00CE8DD9264F9FF9 ON dbo.PessoaProspectPerfil (  IdPessoaProspect ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.PessoaProspectDadosGerais definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PessoaProspectDadosGerais;

CREATE TABLE SuperCRMDB.dbo.PessoaProspectDadosGerais (
	Id int IDENTITY(1,1) NOT NULL,
	IdPessoaProspect int NOT NULL,
	ValorString varchar(8000) COLLATE Latin1_General_CI_AI NULL,
	ValorInt int NULL,
	ValorDecimal decimal(18,2) NULL,
	Tipo varchar(100) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	DtAtualizacao datetime NULL,
	IdUsuarioContaSistema int NULL,
	CONSTRAINT PK_PESSOAPROSPECTDADOSGERAIS PRIMARY KEY (Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_PE4123 FOREIGN KEY (IdPessoaProspect) REFERENCES SuperCRMDB.dbo.PessoaProspect(Id) ON DELETE CASCADE,
	CONSTRAINT FK_PESSOAPR_REFERENCE_USU552 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX IDXPESSOAPROSPECT ON dbo.PessoaProspectDadosGerais (  IdPessoaProspect ASC  , Tipo ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.IntegraLeads definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.IntegraLeads;

CREATE TABLE SuperCRMDB.dbo.IntegraLeads (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdentificadorKey varchar(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdContaSistema int NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	IdIntegradoraExterna int NOT NULL,
	IdIntegradoraExternaAgencia int NOT NULL,
	IdCampanha int NOT NULL,
	IdCanal int NOT NULL,
	IdMidia int NULL,
	IdPeca int NULL,
	IdProduto int NULL,
	IdPoliticaPrivacidade int NULL,
	Tipo varchar(15) COLLATE Latin1_General_CI_AI NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	Obs varchar(500) COLLATE Latin1_General_CI_AI NULL,
	ObjJson varchar(1000) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_INTEGRALEADS PRIMARY KEY (Id),
	CONSTRAINT FK_INTEGRAL_IntegradoraExterna FOREIGN KEY (IdIntegradoraExterna) REFERENCES SuperCRMDB.dbo.IntegradoraExterna(Id),
	CONSTRAINT FK_INTEGRAL_IntegradoraExternaAgencia FOREIGN KEY (IdIntegradoraExternaAgencia) REFERENCES SuperCRMDB.dbo.IntegradoraExterna(Id),
	CONSTRAINT FK_INTEGRAL_REFERENCE_CA444 FOREIGN KEY (IdCanal) REFERENCES SuperCRMDB.dbo.Canal(Id),
	CONSTRAINT FK_INTEGRAL_REFERENCE_CAMPA477 FOREIGN KEY (IdCampanha) REFERENCES SuperCRMDB.dbo.Campanha(Id),
	CONSTRAINT FK_INTEGRAL_REFERENCE_CON4587 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id) ON DELETE CASCADE,
	CONSTRAINT FK_INTEGRAL_REFERENCE_MI784 FOREIGN KEY (IdMidia) REFERENCES SuperCRMDB.dbo.Midia(Id),
	CONSTRAINT FK_INTEGRAL_REFERENCE_PE7dd FOREIGN KEY (IdPeca) REFERENCES SuperCRMDB.dbo.Peca(Id),
	CONSTRAINT FK_INTEGRAL_REFERENCE_POLI785 FOREIGN KEY (IdPoliticaPrivacidade) REFERENCES SuperCRMDB.dbo.PoliticaDePrivacidade(Id),
	CONSTRAINT FK_INTEGRAL_REFERENCE_PROD77ee FOREIGN KEY (IdProduto) REFERENCES SuperCRMDB.dbo.Produto(Id),
	CONSTRAINT FK_INTEGRAL_REFERENCE_US295 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxGuidUnique ON dbo.IntegraLeads (  IdGuid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdentificadorKey ON dbo.IntegraLeads (  IdentificadorKey ASC  )  
	 INCLUDE ( IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
ALTER TABLE SuperCRMDB.dbo.IntegraLeads WITH NOCHECK ADD CONSTRAINT CKC_OBJJSON_INTEGRAL CHECK ([ObjJson] IS NULL OR isjson([ObjJson])=(1));


-- SuperCRMDB.dbo.MidiaInvestimento definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.MidiaInvestimento;

CREATE TABLE SuperCRMDB.dbo.MidiaInvestimento (
	Id int IDENTITY(1,1) NOT NULL,
	IdMidia int NOT NULL,
	DtInicio date NOT NULL,
	DtFim date NOT NULL,
	Valor decimal(18,5) NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	DtInclusao datetime NOT NULL,
	CONSTRAINT PK_MIDIAINVESTIMENTO PRIMARY KEY (Id),
	CONSTRAINT FK_MIDIAINV_REFERENCE_MI457 FOREIGN KEY (IdMidia) REFERENCES SuperCRMDB.dbo.Midia(Id) ON DELETE CASCADE
);
 CREATE NONCLUSTERED INDEX IDX1 ON dbo.MidiaInvestimento (  IdMidia ASC  , DtInicio ASC  , DtFim ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.RemessaDC definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.RemessaDC;

CREATE TABLE SuperCRMDB.dbo.RemessaDC (
	IdRemessa int NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	DtInclusao datetime NOT NULL,
	Status varchar(35) COLLATE Latin1_General_CI_AI NOT NULL,
	DtStatus datetime NOT NULL,
	StatusProcessamento varchar(35) COLLATE Latin1_General_CI_AI NOT NULL,
	DtStatusProcessamento datetime NOT NULL,
	NumOrigem varchar(15) COLLATE Latin1_General_CI_AI NOT NULL,
	NumDestino varchar(15) COLLATE Latin1_General_CI_AI NOT NULL,
	CallerId char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	MostrarNumeroOrigem bit NOT NULL,
	Gravada bit NOT NULL,
	Custo decimal(18,5) NOT NULL,
	DtInicio datetime NULL,
	DtFim datetime NULL,
	GravacaoLink varchar(1000) COLLATE Latin1_General_CI_AI NULL,
	StatusOrigem varchar(35) COLLATE Latin1_General_CI_AI NULL,
	StatusDestino varchar(35) COLLATE Latin1_General_CI_AI NULL,
	OrigemDtChamada datetime NULL,
	OrigemDtAtendida datetime NULL,
	OrigemDtFinalizada datetime NULL,
	DestinoDtChamada datetime NULL,
	DestinoDtAtendida datetime NULL,
	DestinoDtFinalizada datetime NULL,
	Duracao time NULL,
	OrigemLocalidade varchar(500) COLLATE Latin1_General_CI_AI NULL,
	DestinoLocalidade varchar(500) COLLATE Latin1_General_CI_AI NULL,
	QtdStatusProcessamento int DEFAULT 0 NOT NULL,
	CONSTRAINT PK_REMESSADC PRIMARY KEY (IdRemessa),
	CONSTRAINT FK_REMESSAD_REFERENCE_REME236 FOREIGN KEY (IdRemessa) REFERENCES SuperCRMDB.dbo.RemessaCustom(IdRemessa) ON DELETE CASCADE
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxCallerIdUnique ON dbo.RemessaDC (  CallerId ASC  )  
	 INCLUDE ( IdRemessa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxDtStatusProcessamento ON dbo.RemessaDC (  DtStatusProcessamento ASC  , StatusProcessamento ASC  )  
	 INCLUDE ( DtStatus , IdRemessa , Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuidUnique ON dbo.RemessaDC (  IdGuid ASC  )  
	 INCLUDE ( IdRemessa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxNumDestino ON dbo.RemessaDC (  NumDestino ASC  , NumOrigem ASC  )  
	 INCLUDE ( IdRemessa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxNumOrigem ON dbo.RemessaDC (  NumOrigem ASC  , NumDestino ASC  )  
	 INCLUDE ( IdRemessa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxStatusProcessamento ON dbo.RemessaDC (  StatusProcessamento ASC  , Status ASC  )  
	 INCLUDE ( DtStatus , DtStatusProcessamento , IdRemessa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.PessoaProspectFidelizado definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PessoaProspectFidelizado;

CREATE TABLE SuperCRMDB.dbo.PessoaProspectFidelizado (
	Id int IDENTITY(1,1) NOT NULL,
	IdPessoaProspect int NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	DtInclusao datetime NOT NULL,
	DtInicioFidelizacao datetime NOT NULL,
	Tipo varchar(15) COLLATE Latin1_General_CI_AI NOT NULL,
	DtFimFidelizacao datetime NULL,
	IdCampanha int NULL,
	IdGrupo int NULL,
	IdRegraFidelizacao int NULL,
	CONSTRAINT PK_PESSOAPROSPECTFIDELIZADO PRIMARY KEY (Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_CAMPA4555 FOREIGN KEY (IdCampanha) REFERENCES SuperCRMDB.dbo.Campanha(Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_GR488 FOREIGN KEY (IdGrupo) REFERENCES SuperCRMDB.dbo.Grupo(Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_PESSOAP0 FOREIGN KEY (IdPessoaProspect) REFERENCES SuperCRMDB.dbo.PessoaProspect(Id) ON DELETE CASCADE,
	CONSTRAINT FK_PESSOAPR_REFERENCE_REGR588 FOREIGN KEY (IdRegraFidelizacao) REFERENCES SuperCRMDB.dbo.RegraFidelizacao(Id) ON DELETE SET NULL,
	CONSTRAINT FK_PESSOAPR_REFERENCE_USUARIO2 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.PessoaProspectFidelizado (  IdPessoaProspect ASC  , DtFimFidelizacao ASC  , IdCampanha ASC  )  
	 INCLUDE ( Id , IdUsuarioContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2DtFimFidelizacao ON dbo.PessoaProspectFidelizado (  DtFimFidelizacao ASC  , IdCampanha ASC  )  
	 INCLUDE ( DtInicioFidelizacao , Id , IdGrupo , IdPessoaProspect , IdRegraFidelizacao , IdUsuarioContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxDtFimFidelizacao ON dbo.PessoaProspectFidelizado (  DtFimFidelizacao ASC  , IdPessoaProspect ASC  , IdCampanha ASC  , IdRegraFidelizacao ASC  )  
	 INCLUDE ( Id , IdUsuarioContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdPessoaProspect ON dbo.PessoaProspectFidelizado (  IdPessoaProspect ASC  , IdCampanha ASC  , DtFimFidelizacao ASC  )  
	 INCLUDE ( DtInicioFidelizacao , IdGrupo , IdRegraFidelizacao , IdUsuarioContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdUsuarioContaSistema ON dbo.PessoaProspectFidelizado (  IdUsuarioContaSistema ASC  , IdPessoaProspect ASC  )  
	 INCLUDE ( DtFimFidelizacao , DtInicioFidelizacao , IdCampanha , IdGrupo , IdRegraFidelizacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxRegraFidelizacao ON dbo.PessoaProspectFidelizado (  IdRegraFidelizacao ASC  , IdCampanha ASC  )  
	 INCLUDE ( DtFimFidelizacao , Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.InteracaoMarketing definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.InteracaoMarketing;

CREATE TABLE SuperCRMDB.dbo.InteracaoMarketing (
	Id int IDENTITY(1,1) NOT NULL,
	IdMidia int NULL,
	IdPeca int NULL,
	IdIntegradoraExterna int NULL,
	IdIntegradoraExternaAgencia int NULL,
	DtInclusao datetime NOT NULL,
	Obs varchar(1000) COLLATE Latin1_General_CI_AI NULL,
	IdGrupoPecaMarketing int NULL,
	IdCampanhaMarketing int NULL,
	CONSTRAINT PK_INTERACAOMARKETING PRIMARY KEY (Id),
	CONSTRAINT FK_INTERACA_REFERENCE_CAMPAN963 FOREIGN KEY (IdCampanhaMarketing) REFERENCES SuperCRMDB.dbo.CampanhaMarketing(Id),
	CONSTRAINT FK_INTERACA_REFERENCE_GRUPO895 FOREIGN KEY (IdGrupoPecaMarketing) REFERENCES SuperCRMDB.dbo.GrupoPecaMarketing(Id),
	CONSTRAINT FK_INTERACA_REFERENCE_INTE873 FOREIGN KEY (IdIntegradoraExterna) REFERENCES SuperCRMDB.dbo.IntegradoraExterna(Id),
	CONSTRAINT FK_INTERACA_REFERENCE_INTEAG456 FOREIGN KEY (IdIntegradoraExternaAgencia) REFERENCES SuperCRMDB.dbo.IntegradoraExterna(Id),
	CONSTRAINT FK_INTERACA_REFERENCE_MIDIA87 FOREIGN KEY (IdMidia) REFERENCES SuperCRMDB.dbo.Midia(Id),
	CONSTRAINT FK_INTERACA_REFERENCE_PECA89 FOREIGN KEY (IdPeca) REFERENCES SuperCRMDB.dbo.Peca(Id)
);


-- SuperCRMDB.dbo.Prospeccao definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Prospeccao;

CREATE TABLE SuperCRMDB.dbo.Prospeccao (
	Id int IDENTITY(1,1) NOT NULL,
	IdContaSistema int NOT NULL,
	IdCampanha int NULL,
	IdPeca int NULL,
	IdCanal int NULL,
	IdProduto int NULL,
	Nome varchar(200) COLLATE Latin1_General_CI_AI NOT NULL,
	Descricao varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	DtInclusao datetime NOT NULL,
	DtInicioProspeccao datetime NOT NULL,
	Status varchar(30) COLLATE Latin1_General_CI_AI NOT NULL,
	CriarAtendimentoAtendido bit DEFAULT 0 NOT NULL,
	StatusProspeccao varchar(30) COLLATE Latin1_General_CI_AI DEFAULT 'INCLUIDO' NOT NULL,
	IdMidia int NULL,
	QtdProspectsTotal int DEFAULT 0 NOT NULL,
	QtdProspectsSucesso int DEFAULT 0 NOT NULL,
	QtdProspectErro int DEFAULT 0 NOT NULL,
	IdUsuarioContaSistema int NULL,
	EnviarEmailSobreAtendimento bit DEFAULT 0 NOT NULL,
	StrTagsProspect varchar(8000) COLLATE Latin1_General_CI_AI NULL,
	CriarAtendimentoEncerrado bit DEFAULT 0 NOT NULL,
	TipoTransferencia varchar(35) COLLATE Latin1_General_CI_AI DEFAULT 'ROLETA' NOT NULL,
	RetirarFidelizacao bit DEFAULT 0 NOT NULL,
	DtUltimoProcessamento datetime NOT NULL,
	ForcarDadosImportacao bit DEFAULT 1 NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_PROSPECCAO PRIMARY KEY (Id),
	CONSTRAINT FK_PROSPECC_REFERENCE_C896 FOREIGN KEY (IdCanal) REFERENCES SuperCRMDB.dbo.Canal(Id),
	CONSTRAINT FK_PROSPECC_REFERENCE_CAMPANHA FOREIGN KEY (IdCampanha) REFERENCES SuperCRMDB.dbo.Campanha(Id),
	CONSTRAINT FK_PROSPECC_REFERENCE_CONT896 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id),
	CONSTRAINT FK_PROSPECC_REFERENCE_MI4545 FOREIGN KEY (IdMidia) REFERENCES SuperCRMDB.dbo.Midia(Id) ON DELETE CASCADE,
	CONSTRAINT FK_PROSPECC_REFERENCE_P523 FOREIGN KEY (IdPeca) REFERENCES SuperCRMDB.dbo.Peca(Id),
	CONSTRAINT FK_PROSPECC_REFERENCE_PROD236 FOREIGN KEY (IdProduto) REFERENCES SuperCRMDB.dbo.Produto(Id),
	CONSTRAINT FK_PROSPECC_REFERENCE_USU455 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX idxContaSistema ON dbo.Prospeccao (  IdContaSistema ASC  , Status ASC  )  
	 INCLUDE ( DtInicioProspeccao , DtUltimoProcessamento , StatusProspeccao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.Prospeccao (  IdGuid ASC  )  
	 INCLUDE ( Id , IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxStatus ON dbo.Prospeccao (  Status ASC  , StatusProspeccao ASC  , DtInicioProspeccao ASC  )  
	 INCLUDE ( DtUltimoProcessamento , Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxStatusProspeccao ON dbo.Prospeccao (  StatusProspeccao ASC  , Status ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.ProspeccaoUsuarioContaSistema definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.ProspeccaoUsuarioContaSistema;

CREATE TABLE SuperCRMDB.dbo.ProspeccaoUsuarioContaSistema (
	Id int IDENTITY(1,1) NOT NULL,
	IdProspeccao int NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	DtUltimoAtendimento datetime NOT NULL,
	CONSTRAINT PK_PROSPECCAOUSUARIOCONTASISTE PRIMARY KEY (Id),
	CONSTRAINT FK_PROSPECC_REFERENCE_PROS458 FOREIGN KEY (IdProspeccao) REFERENCES SuperCRMDB.dbo.Prospeccao(Id) ON DELETE CASCADE,
	CONSTRAINT FK_PROSPECC_REFERENCE_USUA8754 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id) ON DELETE CASCADE
);
 CREATE NONCLUSTERED INDEX idx1 ON dbo.ProspeccaoUsuarioContaSistema (  IdProspeccao ASC  , IdUsuarioContaSistema ASC  )  
	 INCLUDE ( DtUltimoAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2 ON dbo.ProspeccaoUsuarioContaSistema (  IdUsuarioContaSistema ASC  , IdProspeccao ASC  )  
	 INCLUDE ( DtUltimoAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.ProspeccaoPessoaProspectOrigem definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.ProspeccaoPessoaProspectOrigem;

CREATE TABLE SuperCRMDB.dbo.ProspeccaoPessoaProspectOrigem (
	Id int IDENTITY(1,1) NOT NULL,
	IdPessoaProspectOrigem int NOT NULL,
	IdProspeccao int NOT NULL,
	DtInclusao datetime NOT NULL,
	CONSTRAINT PK_PROSPECCAOPESSOAPROSPECTORI PRIMARY KEY (Id),
	CONSTRAINT FK_PROSPECC_REFERENCE_PESSO478 FOREIGN KEY (IdPessoaProspectOrigem) REFERENCES SuperCRMDB.dbo.PessoaProspectOrigem(Id) ON DELETE CASCADE,
	CONSTRAINT FK_PROSPECC_REFERENCE_PROSP547 FOREIGN KEY (IdProspeccao) REFERENCES SuperCRMDB.dbo.Prospeccao(Id) ON DELETE CASCADE
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdPessoaProspectOrigem ON dbo.ProspeccaoPessoaProspectOrigem (  IdPessoaProspectOrigem ASC  , IdProspeccao ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdProspeccao ON dbo.ProspeccaoPessoaProspectOrigem (  IdProspeccao ASC  , IdPessoaProspectOrigem ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.ProspeccaoTag definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.ProspeccaoTag;

CREATE TABLE SuperCRMDB.dbo.ProspeccaoTag (
	Id int IDENTITY(1,1) NOT NULL,
	IdProspeccao int NOT NULL,
	StrTag varchar(8000) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_PROSPECCAOTAG PRIMARY KEY (Id),
	CONSTRAINT FK_PROSPECC_REFERENCE_PROSP785 FOREIGN KEY (IdProspeccao) REFERENCES SuperCRMDB.dbo.Prospeccao(Id) ON DELETE CASCADE
);
 CREATE NONCLUSTERED INDEX IDX1 ON dbo.ProspeccaoTag (  IdProspeccao ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX IDX2 ON dbo.ProspeccaoTag (  IdProspeccao ASC  , StrTag ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Interacao definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Interacao;

CREATE TABLE SuperCRMDB.dbo.Interacao (
	Id int IDENTITY(1,1) NOT NULL,
	IdSuperEntidade int NOT NULL,
	IdUsuarioContaSistema int NULL,
	DtInclusao datetime NOT NULL,
	Tipo varchar(20) COLLATE Latin1_General_CI_AI NOT NULL,
	IdUsuarioContaSistemaRealizou int NULL,
	IdCanal int NULL,
	IdInteracaoTipo int NOT NULL,
	IdAlarme int NULL,
	InteracaoAtorPartida varchar(30) COLLATE Latin1_General_CI_AI NULL,
	DtInteracao datetime NULL,
	DtConclusao datetime NULL,
	Realizado bit DEFAULT 0 NOT NULL,
	IdInteracaoMarketing int NULL,
	IdProduto int NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NOT NULL,
	ObjTipo varchar(300) COLLATE Latin1_General_CI_AI NULL,
	ObjVersao int NULL,
	IdInteracaoParent int NULL,
	TipoCriacao varchar(10) COLLATE Latin1_General_CI_AI DEFAULT 'AUTO' NULL,
	IdContaSistema int NULL,
	ObjTipoSub varchar(300) COLLATE Latin1_General_CI_AI NULL,
	versao timestamp NOT NULL,
	Importado bit NULL,
	CONSTRAINT PK_ATIVIDADE PRIMARY KEY (Id),
	CONSTRAINT FK_ATIVIDAD_REFERENCE_C523 FOREIGN KEY (IdCanal) REFERENCES SuperCRMDB.dbo.Canal(Id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT FK_COMUNICA_REFERENCE_SU455 FOREIGN KEY (IdSuperEntidade) REFERENCES SuperCRMDB.dbo.SuperEntidade(Id) ON DELETE CASCADE,
	CONSTRAINT FK_COMUNICA_REFERENCE_US4722 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id),
	CONSTRAINT FK_INTERACA_REFERENCE_ALAR458 FOREIGN KEY (IdAlarme) REFERENCES SuperCRMDB.dbo.Alarme(Id) ON DELETE SET NULL ON UPDATE SET NULL,
	CONSTRAINT FK_INTERACA_REFERENCE_INT784 FOREIGN KEY (IdInteracaoTipo) REFERENCES SuperCRMDB.dbo.InteracaoTipo(Id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT FK_INTERACA_REFERENCE_INTEx785 FOREIGN KEY (IdInteracaoMarketing) REFERENCES SuperCRMDB.dbo.InteracaoMarketing(Id),
	CONSTRAINT FK_INTERACA_REFERENCE_PRODU225 FOREIGN KEY (IdProduto) REFERENCES SuperCRMDB.dbo.Produto(Id),
	CONSTRAINT FK_INTERACA_REFERENCE_USU0478 FOREIGN KEY (IdUsuarioContaSistemaRealizou) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id) ON DELETE CASCADE ON UPDATE CASCADE
);
 CREATE NONCLUSTERED INDEX idxDtInclusao ON dbo.Interacao (  DtInclusao DESC  , IdInteracaoTipo ASC  )  
	 INCLUDE ( IdContaSistema , IdSuperEntidade ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxDtInclusao2 ON dbo.Interacao (  DtInclusao ASC  , DtInteracao ASC  , DtConclusao ASC  )  
	 INCLUDE ( IdContaSistema , IdInteracaoTipo , IdSuperEntidade , versao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxDtInteracao ON dbo.Interacao (  DtInteracao DESC  , IdSuperEntidade ASC  )  
	 INCLUDE ( IdContaSistema , IdInteracaoTipo ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdAlarmeUnique ON dbo.Interacao (  IdAlarme ASC  )  
	 INCLUDE ( IdContaSistema , IdInteracaoTipo , IdSuperEntidade , IdUsuarioContaSistema ) 
	 WHERE  ([IdAlarme] IS NOT NULL)
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.Interacao (  IdContaSistema ASC  , IdSuperEntidade ASC  )  
	 INCLUDE ( DtInclusao , Id , IdAlarme , IdInteracaoParent , IdInteracaoTipo , IdUsuarioContaSistema , InteracaoAtorPartida , ObjTipoSub , Tipo , versao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuidUnique ON dbo.Interacao (  IdGuid ASC  )  
	 INCLUDE ( IdContaSistema , IdInteracaoTipo , IdSuperEntidade ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdInteracaoMarketing ON dbo.Interacao (  IdInteracaoMarketing ASC  , IdSuperEntidade ASC  )  
	 INCLUDE ( IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdInteracaoParent ON dbo.Interacao (  IdInteracaoParent ASC  , IdSuperEntidade ASC  )  
	 INCLUDE ( IdContaSistema ) 
	 WHERE  ([IdInteracaoParent] IS NOT NULL)
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdInteracaoTipo2 ON dbo.Interacao (  IdInteracaoTipo ASC  , DtInclusao DESC  , DtInteracao DESC  , DtConclusao DESC  )  
	 INCLUDE ( Id , IdContaSistema , IdSuperEntidade , versao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdSuperEntidade ON dbo.Interacao (  IdSuperEntidade ASC  , Tipo ASC  , ObjTipoSub ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , Id , IdAlarme , IdContaSistema , IdInteracaoParent , IdInteracaoTipo , IdUsuarioContaSistema , InteracaoAtorPartida , versao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxVersao ON dbo.Interacao (  versao ASC  , Id ASC  )  
	 INCLUDE ( IdInteracaoTipo , IdSuperEntidade ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Atendimento definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Atendimento;

CREATE TABLE SuperCRMDB.dbo.Atendimento (
	Id int NOT NULL,
	DtPrazoMaxConclusao datetime NULL,
	DtConclusaoAtendimento datetime NULL,
	StatusAtendimento varchar(40) COLLATE Latin1_General_CI_AI NOT NULL,
	idClassificacao int NULL,
	IdMotivacaoNaoConversaoVenda int NULL,
	IdUsuarioContaSistemaAtendimento int NULL,
	idUsuarioContaSistemaCriacao int NULL,
	idAtendimentoReferente int NULL,
	idPlantao int NULL,
	idGrupo int NULL,
	idCanalCriacao int NOT NULL,
	idPessoaProspect int NOT NULL,
	idCampanha int NOT NULL,
	idProduto int NULL,
	idPeca int NULL,
	idMidia int NULL,
	QtdInteracaoFila int DEFAULT 0 NOT NULL,
	DtInicioAtendimento datetime NULL,
	DataInicioValidadeAtendimento datetime NULL,
	DataFimValidadeAtendimento datetime NULL,
	DataUltimaInteracaoFila datetime NULL,
	TipoDirecionamento varchar(60) COLLATE Latin1_General_CI_AI NOT NULL,
	QtdDirecionadoParaAtendimento int DEFAULT 0 NOT NULL,
	IdCanalAtendimento int NOT NULL,
	TipoDirecionamentoStatus varchar(60) COLLATE Latin1_General_CI_AI DEFAULT 'CONCLUIDO' NOT NULL,
	IdProspeccao int NULL,
	IdGrupoPecaMarketing int NULL,
	IdCampanhaMarketing int NULL,
	ValorNegocio decimal(18,2) DEFAULT 0 NOT NULL,
	ComissaoNegocio decimal(18,2) DEFAULT 0 NOT NULL,
	RegistroStatus char(3) COLLATE Latin1_General_CI_AI NULL,
	IdInteracaoUsuarioUltima int NULL,
	IdInteracaoProspectUltima int NULL,
	IdInteracaoAutoUltima int NULL,
	IdAlarmeUltimo int NULL,
	IdAlarmeUltimoAtivo int NULL,
	IdAlarmeProximoAtivo int NULL,
	IdContaSistema int NOT NULL,
	InteracaoUsuarioUltimaDt datetime NULL,
	versao timestamp NOT NULL,
	idInteracaoNegociacaoVendaUltima int NULL,
	negociacaoStatus varchar(10) COLLATE Latin1_General_CI_AI DEFAULT 'PADRAO' NOT NULL,
	dtInclusao datetime NOT NULL,
	idGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	RegistroStatusIdUsuarioContaSistema int NULL,
	CONSTRAINT PK_ATENDIMENTO PRIMARY KEY (Id),
	CONSTRAINT FK_ATENDIME_REFERENCE_CAMPA785 FOREIGN KEY (idCampanha) REFERENCES SuperCRMDB.dbo.Campanha(Id),
	CONSTRAINT FK_ATENDIME_REFERENCE_CAMPANHAx10 FOREIGN KEY (IdCampanhaMarketing) REFERENCES SuperCRMDB.dbo.CampanhaMarketing(Id) ON DELETE CASCADE,
	CONSTRAINT FK_ATENDIME_REFERENCE_CANALAtend FOREIGN KEY (IdCanalAtendimento) REFERENCES SuperCRMDB.dbo.Canal(Id),
	CONSTRAINT FK_ATENDIME_REFERENCE_CANALCriacao FOREIGN KEY (idCanalCriacao) REFERENCES SuperCRMDB.dbo.Canal(Id),
	CONSTRAINT FK_ATENDIME_REFERENCE_CLAS500 FOREIGN KEY (idClassificacao) REFERENCES SuperCRMDB.dbo.Classificacao(Id),
	CONSTRAINT FK_ATENDIME_REFERENCE_CONT145 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id),
	CONSTRAINT FK_ATENDIME_REFERENCE_GR996 FOREIGN KEY (idGrupo) REFERENCES SuperCRMDB.dbo.Grupo(Id),
	CONSTRAINT FK_ATENDIME_REFERENCE_GRUPOPECx1 FOREIGN KEY (IdGrupoPecaMarketing) REFERENCES SuperCRMDB.dbo.GrupoPecaMarketing(Id) ON DELETE CASCADE,
	CONSTRAINT FK_ATENDIME_REFERENCE_MIDIA255 FOREIGN KEY (idMidia) REFERENCES SuperCRMDB.dbo.Midia(Id),
	CONSTRAINT FK_ATENDIME_REFERENCE_MOTI458 FOREIGN KEY (IdMotivacaoNaoConversaoVenda) REFERENCES SuperCRMDB.dbo.Motivacao(Id) ON DELETE SET NULL,
	CONSTRAINT FK_ATENDIME_REFERENCE_PECA784 FOREIGN KEY (idPeca) REFERENCES SuperCRMDB.dbo.Peca(Id),
	CONSTRAINT FK_ATENDIME_REFERENCE_PESSO345 FOREIGN KEY (idPessoaProspect) REFERENCES SuperCRMDB.dbo.PessoaProspect(Id),
	CONSTRAINT FK_ATENDIME_REFERENCE_PL4515 FOREIGN KEY (idPlantao) REFERENCES SuperCRMDB.dbo.Plantao(Id) ON DELETE SET DEFAULT,
	CONSTRAINT FK_ATENDIME_REFERENCE_PRO235 FOREIGN KEY (idProduto) REFERENCES SuperCRMDB.dbo.Produto(Id),
	CONSTRAINT FK_ATENDIME_REFERENCE_PROS4578 FOREIGN KEY (IdProspeccao) REFERENCES SuperCRMDB.dbo.Prospeccao(Id) ON DELETE SET NULL ON UPDATE SET NULL,
	CONSTRAINT FK_ATENDIME_REFERENCE_SUPER587 FOREIGN KEY (Id) REFERENCES SuperCRMDB.dbo.SuperEntidade(Id) ON DELETE CASCADE,
	CONSTRAINT FK_ATENDIME_REF_INTE_ULT_AUTO FOREIGN KEY (IdInteracaoAutoUltima) REFERENCES SuperCRMDB.dbo.Interacao(Id),
	CONSTRAINT FK_ATENDIME_REF_INTE_ULT_PROS FOREIGN KEY (IdInteracaoProspectUltima) REFERENCES SuperCRMDB.dbo.Interacao(Id),
	CONSTRAINT FK_ATENDIME_REF_INTE_ULT_USU FOREIGN KEY (IdInteracaoUsuarioUltima) REFERENCES SuperCRMDB.dbo.Interacao(Id),
	CONSTRAINT FK_ATENDIME_USUARIO_ATENDIMENTO FOREIGN KEY (IdUsuarioContaSistemaAtendimento) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id),
	CONSTRAINT FK_ATENDIME_USUARIO_CRIACAO FOREIGN KEY (idUsuarioContaSistemaCriacao) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id),
	CONSTRAINT FK_ATEND_REF_INTERACAVEND_ULT FOREIGN KEY (idInteracaoNegociacaoVendaUltima) REFERENCES SuperCRMDB.dbo.Interacao(Id)
);
 CREATE NONCLUSTERED INDEX Idx2IdInteracaoAutoUltima ON dbo.Atendimento (  IdInteracaoAutoUltima ASC  , StatusAtendimento ASC  )  
	 INCLUDE ( DtInicioAtendimento , Id , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , IdMotivacaoNaoConversaoVenda , idPessoaProspect , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX Idx2IdInteracaoProspectUltima ON dbo.Atendimento (  IdInteracaoProspectUltima ASC  , StatusAtendimento ASC  )  
	 INCLUDE ( DtInicioAtendimento , Id , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , IdMotivacaoNaoConversaoVenda , idPessoaProspect , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX IdxIdInteracaoNegociacaoVendaUltima ON dbo.Atendimento (  idInteracaoNegociacaoVendaUltima ASC  , negociacaoStatus ASC  )  
	 INCLUDE ( Id , idClassificacao , IdContaSistema , IdMotivacaoNaoConversaoVenda , IdUsuarioContaSistemaAtendimento , StatusAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2DataFimValidadeAtendimento ON dbo.Atendimento (  DataFimValidadeAtendimento ASC  , Id ASC  )  
	 INCLUDE ( DtInicioAtendimento , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , StatusAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2Id ON dbo.Atendimento (  Id DESC  , IdUsuarioContaSistemaAtendimento ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInicioAtendimento , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idClassificacao , idGrupo , IdGrupoPecaMarketing , IdInteracaoAutoUltima , IdInteracaoProspectUltima , IdInteracaoUsuarioUltima , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idProduto , IdProspeccao , InteracaoUsuarioUltimaDt , RegistroStatus , StatusAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2IdCanalAtendimento ON dbo.Atendimento (  IdCanalAtendimento ASC  , StatusAtendimento ASC  , TipoDirecionamento ASC  )  
	 INCLUDE ( DataFimValidadeAtendimento , DataInicioValidadeAtendimento , DataUltimaInteracaoFila , DtInicioAtendimento , Id , idCampanha , IdCampanhaMarketing , idCanalCriacao , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao , InteracaoUsuarioUltimaDt , QtdInteracaoFila ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2IdCanalCriacao ON dbo.Atendimento (  idCanalCriacao ASC  )  
	 INCLUDE ( Id , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2IdClassificacao ON dbo.Atendimento (  idClassificacao ASC  , IdContaSistema ASC  )  
	 INCLUDE ( ComissaoNegocio , DtInicioAtendimento , Id , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idGrupo , IdGrupoPecaMarketing , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao , StatusAtendimento , ValorNegocio ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2IdGrupo ON dbo.Atendimento (  idGrupo ASC  )  
	 INCLUDE ( Id , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , IdContaSistema , IdGrupoPecaMarketing , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2IdInteracaoUsuarioUltima ON dbo.Atendimento (  IdInteracaoUsuarioUltima ASC  , StatusAtendimento ASC  )  
	 INCLUDE ( DtInicioAtendimento , Id , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , IdMotivacaoNaoConversaoVenda , idPessoaProspect , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2IdMidia ON dbo.Atendimento (  idMidia ASC  , idPeca ASC  )  
	 INCLUDE ( Id , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , IdMotivacaoNaoConversaoVenda , idPessoaProspect , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2IdMotivacaoNaoConversaoVenda ON dbo.Atendimento (  IdMotivacaoNaoConversaoVenda ASC  , StatusAtendimento ASC  )  
	 INCLUDE ( Id , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , idMidia , idPeca , idPessoaProspect , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2IdPeca ON dbo.Atendimento (  idPeca ASC  , idMidia ASC  )  
	 INCLUDE ( Id , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , IdMotivacaoNaoConversaoVenda , idPessoaProspect , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2IdPessoaProspect ON dbo.Atendimento (  idPessoaProspect ASC  , IdContaSistema ASC  )  
	 INCLUDE ( Id , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , idGrupo , IdGrupoPecaMarketing , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao , StatusAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2IdPlantao ON dbo.Atendimento (  idPlantao ASC  )  
	 INCLUDE ( Id , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2IdProduto ON dbo.Atendimento (  idProduto ASC  , StatusAtendimento ASC  )  
	 INCLUDE ( DtInicioAtendimento , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idPlantao , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2IdProspeccao ON dbo.Atendimento (  IdProspeccao ASC  )  
	 INCLUDE ( DataUltimaInteracaoFila , Id , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idPlantao , idProduto , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao , QtdInteracaoFila , StatusAtendimento , TipoDirecionamento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2IdUsuarioContaSistemaAtendimento ON dbo.Atendimento (  IdUsuarioContaSistemaAtendimento ASC  , StatusAtendimento ASC  )  
	 INCLUDE ( idCampanha , IdCanalAtendimento , IdContaSistema , idGrupo , idPessoaProspect ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2IdUsuarioContaSistemaCriacao ON dbo.Atendimento (  idUsuarioContaSistemaCriacao ASC  )  
	 INCLUDE ( Id , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2RegistroStatus ON dbo.Atendimento (  RegistroStatus ASC  , StatusAtendimento ASC  )  
	 INCLUDE ( Id , IdContaSistema , idPessoaProspect ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx3StatusAtendimento ON dbo.Atendimento (  StatusAtendimento ASC  , IdUsuarioContaSistemaAtendimento ASC  , DataFimValidadeAtendimento ASC  )  
	 INCLUDE ( DataInicioValidadeAtendimento , DataUltimaInteracaoFila , dtInclusao , DtInicioAtendimento , Id , IdAlarmeUltimo , IdAlarmeUltimoAtivo , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , IdInteracaoUsuarioUltima , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idPlantao , idProduto , IdProspeccao , idUsuarioContaSistemaCriacao , QtdInteracaoFila , RegistroStatus ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx4StatusAtendimento ON dbo.Atendimento (  StatusAtendimento ASC  , TipoDirecionamento ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DataFimValidadeAtendimento , DataUltimaInteracaoFila , dtInclusao , DtInicioAtendimento , Id , IdAlarmeUltimo , IdAlarmeUltimoAtivo , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , idGrupo , IdGrupoPecaMarketing , IdInteracaoUsuarioUltima , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao , InteracaoUsuarioUltimaDt , QtdInteracaoFila , RegistroStatus ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxDtInclusao ON dbo.Atendimento (  dtInclusao ASC  , IdUsuarioContaSistemaAtendimento ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInicioAtendimento , idCampanha , IdCanalAtendimento , idClassificacao , idGrupo , IdMotivacaoNaoConversaoVenda , idPessoaProspect ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.Atendimento (  idGuid ASC  )  
	 INCLUDE ( IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdCampanha ON dbo.Atendimento (  idCampanha ASC  , IdContaSistema ASC  , idProduto ASC  )  
	 INCLUDE ( DtInicioAtendimento , idGrupo , idPessoaProspect , IdUsuarioContaSistemaAtendimento , StatusAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdContaSistema1 ON dbo.Atendimento (  IdContaSistema ASC  , DtInicioAtendimento ASC  )  
	 INCLUDE ( dtInclusao , idCampanha , IdCanalAtendimento , idClassificacao , idGrupo , idGuid , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idProduto , IdUsuarioContaSistemaAtendimento , InteracaoUsuarioUltimaDt , StatusAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdContaSistema3 ON dbo.Atendimento (  IdContaSistema ASC  , StatusAtendimento ASC  , TipoDirecionamento ASC  , TipoDirecionamentoStatus ASC  , DataFimValidadeAtendimento ASC  )  
	 INCLUDE ( DataInicioValidadeAtendimento , dtInclusao , DtInicioAtendimento , idCampanha , IdCanalAtendimento , idClassificacao , idGrupo , idGuid , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idProduto , IdUsuarioContaSistemaAtendimento , InteracaoUsuarioUltimaDt ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdContaSistema4 ON dbo.Atendimento (  IdContaSistema ASC  , IdUsuarioContaSistemaAtendimento ASC  , StatusAtendimento ASC  , idCampanha ASC  , TipoDirecionamento ASC  , idProduto ASC  )  
	 INCLUDE ( DtInicioAtendimento , IdAlarmeUltimoAtivo , IdCanalAtendimento , idGrupo , IdInteracaoUsuarioUltima , idPessoaProspect , InteracaoUsuarioUltimaDt , negociacaoStatus ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdContaSistema5 ON dbo.Atendimento (  IdContaSistema ASC  , RegistroStatus ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdContaSistema6 ON dbo.Atendimento (  IdContaSistema ASC  , IdUsuarioContaSistemaAtendimento ASC  , dtInclusao ASC  )  
	 INCLUDE ( DtInicioAtendimento , idCampanha , idGrupo , idGuid , idPessoaProspect , StatusAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxUnique ON dbo.Atendimento (  idPessoaProspect ASC  , idCampanha ASC  )  
	 INCLUDE ( Id , IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxVersao ON dbo.Atendimento (  versao ASC  , Id ASC  )  
	 INCLUDE ( idCampanha , IdContaSistema , idGrupo , idMidia , idPeca , idPessoaProspect , idProduto ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxVersaoAtendimento ON dbo.Atendimento (  versao ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX nci_wi_Atendimento_1B1EBC8622D8EA6E538B8A56E28EE05F ON dbo.Atendimento (  IdContaSistema ASC  , IdMotivacaoNaoConversaoVenda ASC  , StatusAtendimento ASC  , DtInicioAtendimento ASC  )  
	 INCLUDE ( idCampanha , idGrupo , idGuid , idMidia , idPeca , idPessoaProspect , idProduto , IdUsuarioContaSistemaAtendimento , versao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX nci_wi_Atendimento_9D29D2BBE513DE04AC29B0C563D65915 ON dbo.Atendimento (  IdContaSistema ASC  , StatusAtendimento ASC  , InteracaoUsuarioUltimaDt ASC  )  
	 INCLUDE ( idCampanha , idGrupo , idPessoaProspect , IdUsuarioContaSistemaAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX nci_wi_Atendimento_FA1C81D7F8DEAEC143F3FF553B737AAF ON dbo.Atendimento (  idClassificacao ASC  , IdUsuarioContaSistemaAtendimento ASC  , StatusAtendimento ASC  )  
	 INCLUDE ( ComissaoNegocio , idProduto , ValorNegocio ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX ridx_Atendimento ON dbo.Atendimento (  idCampanha ASC  , TipoDirecionamento ASC  , StatusAtendimento ASC  )  
	 INCLUDE ( DataUltimaInteracaoFila , DtInicioAtendimento , IdAlarmeUltimo , IdAlarmeUltimoAtivo , IdCanalAtendimento , IdContaSistema , IdInteracaoUsuarioUltima , idPessoaProspect , IdProspeccao , QtdInteracaoFila ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Email definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Email;

CREATE TABLE SuperCRMDB.dbo.Email (
	Id int IDENTITY(1,1) NOT NULL,
	IdInteracao int NOT NULL,
	Assunto varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	BodyText varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	BodyHtml varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	Remetente varchar(3000) COLLATE Latin1_General_CI_AI NULL,
	Destinatario varchar(3000) COLLATE Latin1_General_CI_AI NULL,
	Tipo varchar(30) COLLATE Latin1_General_CI_AI NOT NULL,
	Token varchar(1000) COLLATE Latin1_General_CI_AI NULL,
	Signature varchar(1000) COLLATE Latin1_General_CI_AI NULL,
	Identificador varchar(1000) COLLATE Latin1_General_CI_AI NULL,
	StrippedHtml varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	StrippedText varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	RemetenteMask varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	DestinatarioMask varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_EMAIL PRIMARY KEY (Id),
	CONSTRAINT FK_EMAIL_REFERENCE_ATIVI4444 FOREIGN KEY (IdInteracao) REFERENCES SuperCRMDB.dbo.Interacao(Id) ON DELETE CASCADE
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDXATIVIDADE ON dbo.Email (  IdInteracao ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.PessoaProspectOrigemPessoaProspect definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.PessoaProspectOrigemPessoaProspect;

CREATE TABLE SuperCRMDB.dbo.PessoaProspectOrigemPessoaProspect (
	Id int IDENTITY(1,1) NOT NULL,
	IdPessoaProspect int NOT NULL,
	IdPessoaProspectOrigem int NOT NULL,
	DtInclusao datetime NOT NULL,
	Observacao varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	IdAtendimento int NULL,
	IdPessoaProspectImportacaoTemp int NULL,
	CONSTRAINT PK_PESSOAPROSPECTORIGEMPESSOAP PRIMARY KEY (Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_ATENDI145 FOREIGN KEY (IdAtendimento) REFERENCES SuperCRMDB.dbo.Atendimento(Id) ON DELETE CASCADE,
	CONSTRAINT FK_PESSOAPR_REFERENCE_PESSO298 FOREIGN KEY (IdPessoaProspectImportacaoTemp) REFERENCES SuperCRMDB.dbo.PessoaProspectImportacaoTemp(Id),
	CONSTRAINT FK_PESSOAPR_REFERENCE_PESSOA50 FOREIGN KEY (IdPessoaProspectOrigem) REFERENCES SuperCRMDB.dbo.PessoaProspectOrigem(Id) ON DELETE CASCADE,
	CONSTRAINT FK_PESSOAPR_REFERENCE_PESSOA51 FOREIGN KEY (IdPessoaProspect) REFERENCES SuperCRMDB.dbo.PessoaProspect(Id) ON UPDATE CASCADE
);
 CREATE NONCLUSTERED INDEX idxIdAtendimento ON dbo.PessoaProspectOrigemPessoaProspect (  IdAtendimento ASC  , IdPessoaProspect ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdPessoaProspect ON dbo.PessoaProspectOrigemPessoaProspect (  IdPessoaProspect ASC  , IdPessoaProspectOrigem ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdPessoaProspectImportacaoTemp ON dbo.PessoaProspectOrigemPessoaProspect (  IdPessoaProspectImportacaoTemp ASC  )  
	 INCLUDE ( Id , IdPessoaProspect ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdPessoaProspectOrigem ON dbo.PessoaProspectOrigemPessoaProspect (  IdPessoaProspectOrigem ASC  )  
	 INCLUDE ( Id , IdAtendimento , IdPessoaProspect ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.ProspeccaoPessoaProspect definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.ProspeccaoPessoaProspect;

CREATE TABLE SuperCRMDB.dbo.ProspeccaoPessoaProspect (
	Id int IDENTITY(1,1) NOT NULL,
	IdPessoaProspect int NOT NULL,
	IdProspeccao int NOT NULL,
	IdPessoaProspectOrigemPessoaProspect int NULL,
	DtInclusao datetime NOT NULL,
	DtStatus datetime NOT NULL,
	Status varchar(30) COLLATE Latin1_General_CI_AI NOT NULL,
	Obs varchar(8000) COLLATE Latin1_General_CI_AI NULL,
	StrTag varchar(8000) COLLATE Latin1_General_CI_AI NULL,
	IdAtendimento int NULL,
	CONSTRAINT PK_PROSPECCAOPESSOAPROSPECT PRIMARY KEY (Id),
	CONSTRAINT FK_PROSPECC_REFERENCE_PESSO523 FOREIGN KEY (IdPessoaProspectOrigemPessoaProspect) REFERENCES SuperCRMDB.dbo.PessoaProspectOrigemPessoaProspect(Id) ON DELETE CASCADE,
	CONSTRAINT FK_PROSPECC_REFERENCE_PESSO63 FOREIGN KEY (IdPessoaProspect) REFERENCES SuperCRMDB.dbo.PessoaProspect(Id) ON DELETE CASCADE,
	CONSTRAINT FK_PROSPECC_REFERENCE_PROS4545 FOREIGN KEY (IdProspeccao) REFERENCES SuperCRMDB.dbo.Prospeccao(Id) ON DELETE CASCADE
);
 CREATE NONCLUSTERED INDEX idxAtendimento ON dbo.ProspeccaoPessoaProspect (  IdAtendimento ASC  , IdPessoaProspect ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdPessoaProspect ON dbo.ProspeccaoPessoaProspect (  IdPessoaProspect ASC  , IdProspeccao ASC  , IdAtendimento ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdPessoaProspectOrigemPessoaProspect ON dbo.ProspeccaoPessoaProspect (  IdPessoaProspectOrigemPessoaProspect ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdProspeccao ON dbo.ProspeccaoPessoaProspect (  IdProspeccao ASC  , Status ASC  )  
	 INCLUDE ( DtInclusao , DtStatus , IdAtendimento , IdPessoaProspect , IdPessoaProspectOrigemPessoaProspect , StrTag ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX nci_wi_ProspeccaoPessoaProspect_77261E9526D13D4C901762FBEF38AC3B ON dbo.ProspeccaoPessoaProspect (  IdProspeccao ASC  )  
	 INCLUDE ( DtInclusao , DtStatus , IdAtendimento , IdPessoaProspect , IdPessoaProspectOrigemPessoaProspect , Obs , Status , StrTag ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.RespostaFichaPesquisa definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.RespostaFichaPesquisa;

CREATE TABLE SuperCRMDB.dbo.RespostaFichaPesquisa (
	Id int IDENTITY(1,1) NOT NULL,
	IdFichaPesquisa int NOT NULL,
	IdPessoaProspect int NOT NULL,
	IdAtendimento int NULL,
	IdPergunta int NOT NULL,
	FichaPesquisaTipo varchar(50) COLLATE Latin1_General_CI_AI DEFAULT 'PREENCHIMENTO_USUARIO' NOT NULL,
	CONSTRAINT PK_RESPOSTAFICHAPERFIL PRIMARY KEY (Id),
	CONSTRAINT FK_RESPOSTA_REFERENCE_ATENDIME FOREIGN KEY (IdAtendimento) REFERENCES SuperCRMDB.dbo.Atendimento(Id) ON DELETE CASCADE,
	CONSTRAINT FK_RESPOSTA_REFERENCE_FICHAPES FOREIGN KEY (IdFichaPesquisa) REFERENCES SuperCRMDB.dbo.FichaPesquisa(Id),
	CONSTRAINT FK_RESPOSTA_REFERENCE_PERGUNT2 FOREIGN KEY (IdPergunta) REFERENCES SuperCRMDB.dbo.Pergunta(Id),
	CONSTRAINT FK_RESPOSTA_REFERENCE_PESSOAPR FOREIGN KEY (IdPessoaProspect) REFERENCES SuperCRMDB.dbo.PessoaProspect(Id) ON UPDATE CASCADE
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.RespostaFichaPesquisa (  IdFichaPesquisa ASC  , IdPergunta ASC  , FichaPesquisaTipo ASC  , IdAtendimento ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx1 ON dbo.RespostaFichaPesquisa (  IdFichaPesquisa ASC  , IdAtendimento ASC  , FichaPesquisaTipo ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdAtendimento ON dbo.RespostaFichaPesquisa (  IdAtendimento ASC  , IdFichaPesquisa ASC  )  
	 INCLUDE ( FichaPesquisaTipo , Id , IdPergunta ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdPessoaProspect ON dbo.RespostaFichaPesquisa (  IdPessoaProspect ASC  )  
	 INCLUDE ( IdAtendimento , IdPergunta ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.AtendimentoSeguidor definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.AtendimentoSeguidor;

CREATE TABLE SuperCRMDB.dbo.AtendimentoSeguidor (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdAtendimento int NOT NULL,
	IdUsuarioContaSistema int NOT NULL,
	IdUsuarioContaSistemaAdicionou int NULL,
	IdPessoaProspect int NOT NULL,
	DtInclusao datetime NOT NULL,
	Status char(2) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_ATENDIMENTOSEGUIDOR PRIMARY KEY (Id),
	CONSTRAINT FK_ATENDIME_REFERENCE_ATEND234 FOREIGN KEY (IdAtendimento) REFERENCES SuperCRMDB.dbo.Atendimento(Id) ON DELETE CASCADE,
	CONSTRAINT FK_ATENDIME_REFERENCE_PESSOyd8 FOREIGN KEY (IdPessoaProspect) REFERENCES SuperCRMDB.dbo.PessoaProspect(Id) ON DELETE CASCADE,
	CONSTRAINT FK_ATENDIME_REFERENCE_USUA229 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id) ON DELETE CASCADE,
	CONSTRAINT FK_ATENDIME_REFERENCE_USUA987 FOREIGN KEY (IdUsuarioContaSistemaAdicionou) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX idxIdAtendimento ON dbo.AtendimentoSeguidor (  IdAtendimento ASC  , IdUsuarioContaSistema ASC  , Status ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdGuid ON dbo.AtendimentoSeguidor (  IdGuid ASC  )  
	 INCLUDE ( IdAtendimento , IdUsuarioContaSistema , Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdPessoaProspect ON dbo.AtendimentoSeguidor (  IdPessoaProspect ASC  , IdUsuarioContaSistema ASC  , Status ASC  )  
	 INCLUDE ( Id , IdAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdUsuarioContaSistema ON dbo.AtendimentoSeguidor (  IdUsuarioContaSistema ASC  , IdAtendimento ASC  )  
	 INCLUDE ( Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.Ligacao definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.Ligacao;

CREATE TABLE SuperCRMDB.dbo.Ligacao (
	Id int IDENTITY(1,1) NOT NULL,
	IdInteracao int NOT NULL,
	IdRemessa int NULL,
	DtInicio datetime NULL,
	DtFim datetime NULL,
	DtStatus datetime NOT NULL,
	Status varchar(15) COLLATE Latin1_General_CI_AI NOT NULL,
	Tipo varchar(15) COLLATE Latin1_General_CI_AI NOT NULL,
	OrigemDDI char(2) COLLATE Latin1_General_CI_AI NULL,
	OrigemDDD char(2) COLLATE Latin1_General_CI_AI NULL,
	OrigemNumero varchar(9) COLLATE Latin1_General_CI_AI NULL,
	DestinoDDI char(2) COLLATE Latin1_General_CI_AI NULL,
	DestinoDDD char(2) COLLATE Latin1_General_CI_AI NULL,
	DestinoNumero char(9) COLLATE Latin1_General_CI_AI NULL,
	Duracao time NULL,
	Custo decimal(18,5) NOT NULL,
	DestinoOriginalDDI char(2) COLLATE Latin1_General_CI_AI NULL,
	DestinoOriginalDDD char(2) COLLATE Latin1_General_CI_AI NULL,
	DestinoOriginalNumero char(9) COLLATE Latin1_General_CI_AI NULL,
	CONSTRAINT PK_LIGACAO PRIMARY KEY (Id),
	CONSTRAINT FK_LIGACAO_REFERENCE_INTER632 FOREIGN KEY (IdInteracao) REFERENCES SuperCRMDB.dbo.Interacao(Id) ON DELETE CASCADE,
	CONSTRAINT FK_LIGACAO_REFERENCE_REMESSA FOREIGN KEY (IdRemessa) REFERENCES SuperCRMDB.dbo.Remessa(Id)
);
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdInteracaoUnique ON dbo.Ligacao (  IdInteracao ASC  )  
	 INCLUDE ( Id , IdRemessa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdRemessa ON dbo.Ligacao (  IdRemessa ASC  , IdInteracao ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.OportunidadeNegocio definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.OportunidadeNegocio;

CREATE TABLE SuperCRMDB.dbo.OportunidadeNegocio (
	IdSuperEntidade int NOT NULL,
	IdOportunidadeNegocioTipo int NULL,
	IdUsuarioContaSistema int NOT NULL,
	IdProduto int NOT NULL,
	IdPessoaProspect int NOT NULL,
	Valor decimal(18,2) NOT NULL,
	Status varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	StatusPos varchar(50) COLLATE Latin1_General_CI_AI NULL,
	DtOportunidade datetime NOT NULL,
	Obs varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	Quantidade int DEFAULT 1 NOT NULL,
	IdUsuarioContaSistemaRegistrou int NULL,
	IdProdutoSub int NULL,
	IdAtendimento int NOT NULL,
	idIntegracao int NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI DEFAULT newid() NULL,
	CONSTRAINT PK_OPORTUNIDADENEGOCIO PRIMARY KEY (IdSuperEntidade),
	CONSTRAINT FK_OPORTUNI_REFERENCE_ATEN587 FOREIGN KEY (IdAtendimento) REFERENCES SuperCRMDB.dbo.Atendimento(Id),
	CONSTRAINT FK_OPORTUNI_REFERENCE_OPOR4587 FOREIGN KEY (IdOportunidadeNegocioTipo) REFERENCES SuperCRMDB.dbo.OportunidadeNegocioTipo(Id),
	CONSTRAINT FK_OPORTUNI_REFERENCE_PESS8957 FOREIGN KEY (IdPessoaProspect) REFERENCES SuperCRMDB.dbo.PessoaProspect(Id) ON DELETE CASCADE,
	CONSTRAINT FK_OPORTUNI_REFERENCE_PRO7895 FOREIGN KEY (IdProduto) REFERENCES SuperCRMDB.dbo.Produto(Id),
	CONSTRAINT FK_OPORTUNI_REFERENCE_PROD45747 FOREIGN KEY (IdProdutoSub) REFERENCES SuperCRMDB.dbo.ProdutoSub(Id),
	CONSTRAINT FK_OPORTUNI_REFERENCE_SUP9872 FOREIGN KEY (IdSuperEntidade) REFERENCES SuperCRMDB.dbo.SuperEntidade(Id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT FK_OPORTUNI_REFERENCE_USU4545 FOREIGN KEY (IdUsuarioContaSistemaRegistrou) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id),
	CONSTRAINT FK_OPORTUNI_REFERENCE_USUA4587 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX idx2DtOportunidade ON dbo.OportunidadeNegocio (  DtOportunidade ASC  )  
	 INCLUDE ( IdAtendimento , IdOportunidadeNegocioTipo , IdPessoaProspect , IdProduto , IdProdutoSub , IdSuperEntidade , IdUsuarioContaSistema , IdUsuarioContaSistemaRegistrou ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2IdAtendimento ON dbo.OportunidadeNegocio (  IdAtendimento ASC  )  
	 INCLUDE ( IdOportunidadeNegocioTipo , IdPessoaProspect , IdProduto , IdProdutoSub , IdSuperEntidade , IdUsuarioContaSistema , IdUsuarioContaSistemaRegistrou ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2IdOportunidadeNegocioTipo ON dbo.OportunidadeNegocio (  IdOportunidadeNegocioTipo ASC  )  
	 INCLUDE ( IdAtendimento , IdPessoaProspect , IdProduto , IdProdutoSub , IdSuperEntidade , IdUsuarioContaSistema , IdUsuarioContaSistemaRegistrou ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2IdPessoaProspect ON dbo.OportunidadeNegocio (  IdPessoaProspect ASC  )  
	 INCLUDE ( IdAtendimento , IdOportunidadeNegocioTipo , IdProduto , IdProdutoSub , IdSuperEntidade , IdUsuarioContaSistema , IdUsuarioContaSistemaRegistrou ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2IdProduto ON dbo.OportunidadeNegocio (  IdProduto ASC  )  
	 INCLUDE ( IdAtendimento , IdOportunidadeNegocioTipo , IdPessoaProspect , IdProdutoSub , IdSuperEntidade , IdUsuarioContaSistema , IdUsuarioContaSistemaRegistrou ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2IdProdutoSub ON dbo.OportunidadeNegocio (  IdProdutoSub ASC  )  
	 INCLUDE ( IdAtendimento , IdOportunidadeNegocioTipo , IdPessoaProspect , IdProduto , IdSuperEntidade , IdUsuarioContaSistema , IdUsuarioContaSistemaRegistrou ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2IdSuperEntidade ON dbo.OportunidadeNegocio (  IdSuperEntidade ASC  )  
	 INCLUDE ( IdAtendimento , IdOportunidadeNegocioTipo , IdPessoaProspect , IdProduto , IdProdutoSub , IdUsuarioContaSistema , IdUsuarioContaSistemaRegistrou ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2IdUsuarioContaSistema ON dbo.OportunidadeNegocio (  IdUsuarioContaSistema ASC  )  
	 INCLUDE ( IdAtendimento , IdOportunidadeNegocioTipo , IdPessoaProspect , IdProduto , IdProdutoSub , IdSuperEntidade , IdUsuarioContaSistemaRegistrou ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2IdUsuarioContaSistemaRegistrou ON dbo.OportunidadeNegocio (  IdUsuarioContaSistemaRegistrou ASC  )  
	 INCLUDE ( IdAtendimento , IdOportunidadeNegocioTipo , IdPessoaProspect , IdProduto , IdProdutoSub , IdSuperEntidade , IdUsuarioContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.EnrichPersonSolicitante definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.EnrichPersonSolicitante;

CREATE TABLE SuperCRMDB.dbo.EnrichPersonSolicitante (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdEnrichPerson int NOT NULL,
	IdContaSistema int NOT NULL,
	IdPessoaProspect int NOT NULL,
	IdUsuarioContaSistema int NULL,
	IdAtendimento int NULL,
	DtInclusao datetime NOT NULL,
	MatchNew bit DEFAULT 0 NOT NULL,
	ObjQuery varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	CONSTRAINT PK_ENRICHPERSONSOLICITANTE PRIMARY KEY (Id),
	CONSTRAINT FK_ENRICHPE_REFERENCE_ATEN4578 FOREIGN KEY (IdAtendimento) REFERENCES SuperCRMDB.dbo.Atendimento(Id) ON DELETE SET NULL,
	CONSTRAINT FK_ENRICHPE_REFERENCE_CON581 FOREIGN KEY (IdContaSistema) REFERENCES SuperCRMDB.dbo.ContaSistema(Id),
	CONSTRAINT FK_ENRICHPE_REFERENCE_ENRIC487 FOREIGN KEY (IdEnrichPerson) REFERENCES SuperCRMDB.dbo.EnrichPerson(Id) ON DELETE CASCADE,
	CONSTRAINT FK_ENRICHPE_REFERENCE_PESSOAPR FOREIGN KEY (IdPessoaProspect) REFERENCES SuperCRMDB.dbo.PessoaProspect(Id),
	CONSTRAINT FK_ENRICHPE_REFERENCE_USUA167 FOREIGN KEY (IdUsuarioContaSistema) REFERENCES SuperCRMDB.dbo.UsuarioContaSistema(Id)
);
 CREATE NONCLUSTERED INDEX idxIdAtendimento ON dbo.EnrichPersonSolicitante (  IdAtendimento ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdEnrichPerson ON dbo.EnrichPersonSolicitante (  IdEnrichPerson ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.EnrichPersonSolicitante (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idxIdPessoaProspect ON dbo.EnrichPersonSolicitante (  IdPessoaProspect ASC  , IdUsuarioContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.AtendimentoFilaInteracao definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.AtendimentoFilaInteracao;

CREATE TABLE SuperCRMDB.dbo.AtendimentoFilaInteracao (
	Id int IDENTITY(1,1) NOT NULL,
	DtInclusao datetime NOT NULL,
	Tipo varchar(30) COLLATE Latin1_General_CI_AI NOT NULL,
	Obs varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	IdAtendimento int NOT NULL,
	CONSTRAINT PK_AtendimentoFilaInteracao PRIMARY KEY (Id),
	CONSTRAINT FK_ATENDIME_REFERENCE_ATEN4545 FOREIGN KEY (IdAtendimento) REFERENCES SuperCRMDB.dbo.Atendimento(Id) ON DELETE CASCADE
);
 CREATE NONCLUSTERED INDEX idxIdAtendimento ON dbo.AtendimentoFilaInteracao (  IdAtendimento ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.EnrichPersonSolicitanteEnrichPersonDataSource definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.EnrichPersonSolicitanteEnrichPersonDataSource;

CREATE TABLE SuperCRMDB.dbo.EnrichPersonSolicitanteEnrichPersonDataSource (
	Id int IDENTITY(1,1) NOT NULL,
	IdGuid char(36) COLLATE Latin1_General_CI_AI NOT NULL,
	IdEnrichPersonDataSource int NOT NULL,
	IdEnrichPersonSolicitante int NOT NULL,
	CONSTRAINT PK_ENRICHPERSONSOLICITANTEENRI PRIMARY KEY (Id),
	CONSTRAINT FK_ENRICHPE_REFERENCE_ENRIC236 FOREIGN KEY (IdEnrichPersonDataSource) REFERENCES SuperCRMDB.dbo.EnrichPersonDataSource(Id),
	CONSTRAINT FK_ENRICHPE_REFERENCE_ENRIC599 FOREIGN KEY (IdEnrichPersonSolicitante) REFERENCES SuperCRMDB.dbo.EnrichPersonSolicitante(Id) ON DELETE CASCADE
);
 CREATE NONCLUSTERED INDEX idxIdEnrichPersonSolicitante ON dbo.EnrichPersonSolicitanteEnrichPersonDataSource (  IdEnrichPersonSolicitante ASC  , IdEnrichPersonDataSource ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.EnrichPersonSolicitanteEnrichPersonDataSource (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.AtendimentoSubProduto definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.AtendimentoSubProduto;

CREATE TABLE SuperCRMDB.dbo.AtendimentoSubProduto (
	Id int IDENTITY(1,1) NOT NULL,
	IdProdutoSub int NOT NULL,
	IdAtendimento int NOT NULL,
	CONSTRAINT PK_PROSPECTCAMPANHASUBPRODUTO PRIMARY KEY (Id),
	CONSTRAINT FK_ATENDIME_REFERENCE_ATE455e FOREIGN KEY (IdAtendimento) REFERENCES SuperCRMDB.dbo.Atendimento(Id) ON DELETE CASCADE
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.AtendimentoSubProduto (  IdAtendimento ASC  , IdProdutoSub ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.InteracaoObj definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.InteracaoObj;

CREATE TABLE SuperCRMDB.dbo.InteracaoObj (
	Id int NOT NULL,
	IdContaSistema int NOT NULL,
	IdSuperEntidade int NOT NULL,
	ObjJson varchar(MAX) COLLATE Latin1_General_CI_AI NOT NULL,
	ObjTipo varchar(300) COLLATE Latin1_General_CI_AI NOT NULL,
	ObjTipoSub varchar(300) COLLATE Latin1_General_CI_AI NOT NULL,
	ObjVersao int NOT NULL,
	JSONClassificacaoId AS (CONVERT([int],json_value([ObjJson],'$.Obj.IdClassificacaoNew'))) PERSISTED,
	CONSTRAINT PK_InteracaoObjTemp PRIMARY KEY (Id),
	CONSTRAINT FK_INTERACAOBJTEMP_REF_INTERACAO FOREIGN KEY (Id) REFERENCES SuperCRMDB.dbo.Interacao(Id) ON DELETE CASCADE
);
 CREATE NONCLUSTERED INDEX idxIdSuperEntidade ON dbo.InteracaoObj (  IdSuperEntidade ASC  , ObjTipoSub ASC  )  
	 INCLUDE ( IdContaSistema , JSONClassificacaoId , ObjTipo , ObjVersao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.RespostaFichaPesquisaResposta definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.RespostaFichaPesquisaResposta;

CREATE TABLE SuperCRMDB.dbo.RespostaFichaPesquisaResposta (
	Id int IDENTITY(1,1) NOT NULL,
	IdRespostaFichaPesquisa int NOT NULL,
	IdUsuarioContaSistema int NULL,
	IdResposta int NOT NULL,
	DtInclusao datetime NOT NULL,
	DtAtualizacaoAuto datetime DEFAULT [dbo].[GetDateCustom]() NULL,
	CONSTRAINT PK_RESPOSTAFICHAPERFILRESPOSTA PRIMARY KEY (Id),
	CONSTRAINT FK_RESPOSTA_REFERENCE_RESPOST1 FOREIGN KEY (IdRespostaFichaPesquisa) REFERENCES SuperCRMDB.dbo.RespostaFichaPesquisa(Id) ON DELETE CASCADE,
	CONSTRAINT FK_RESPOSTA_REFERENCE_RESPOST2 FOREIGN KEY (IdResposta) REFERENCES SuperCRMDB.dbo.Resposta(Id)
);
 CREATE NONCLUSTERED INDEX idx1 ON dbo.RespostaFichaPesquisaResposta (  IdRespostaFichaPesquisa ASC  , IdResposta ASC  )  
	 INCLUDE ( DtAtualizacaoAuto , Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2 ON dbo.RespostaFichaPesquisaResposta (  IdResposta ASC  , IdRespostaFichaPesquisa ASC  )  
	 INCLUDE ( DtAtualizacaoAuto , Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx3 ON dbo.RespostaFichaPesquisaResposta (  DtAtualizacaoAuto ASC  )  
	 INCLUDE ( IdRespostaFichaPesquisa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;


-- SuperCRMDB.dbo.TabelaoFichaPesquisaResposta definition

-- Drop table

-- DROP TABLE SuperCRMDB.dbo.TabelaoFichaPesquisaResposta;

CREATE TABLE SuperCRMDB.dbo.TabelaoFichaPesquisaResposta (
	Id int IDENTITY(1,1) NOT NULL,
	DtInclusao datetime NOT NULL,
	RespostaFichaPesquisaRespostaId int NOT NULL,
	IdContaSistema int NOT NULL,
	IdUsuarioContaSistemaRespondido int NULL,
	IdAtendimento int NOT NULL,
	FichaPesquisaId int NOT NULL,
	FichaPesquisaNome varchar(400) COLLATE Latin1_General_CI_AI NOT NULL,
	FichaPesquisaDescricao varchar(MAX) COLLATE Latin1_General_CI_AI NULL,
	PerguntaId int NOT NULL,
	PerguntaDescricao varchar(8000) COLLATE Latin1_General_CI_AI NOT NULL,
	PerguntaTipo varchar(10) COLLATE Latin1_General_CI_AI NOT NULL,
	PerguntaObrigatorio bit NOT NULL,
	RespostaDescricao varchar(8000) COLLATE Latin1_General_CI_AI NOT NULL,
	RespostaPeso int NOT NULL,
	RespostaDtRespondido datetime NOT NULL,
	RespostaFichaPesquisaFichaPesquisaTipo varchar(50) COLLATE Latin1_General_CI_AI NOT NULL,
	DtAtualizacaoAuto datetime NULL,
	versao timestamp NOT NULL,
	CONSTRAINT PK_TABELAOFICHAPESQUISARESPOST PRIMARY KEY (Id),
	CONSTRAINT FK_TABELAOF_REFERENCE_RESPO856 FOREIGN KEY (RespostaFichaPesquisaRespostaId) REFERENCES SuperCRMDB.dbo.RespostaFichaPesquisaResposta(Id) ON DELETE CASCADE
);
 CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.TabelaoFichaPesquisaResposta (  RespostaFichaPesquisaRespostaId ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
 CREATE NONCLUSTERED INDEX idx2IdAtendimento ON dbo.TabelaoFichaPesquisaResposta (  IdAtendimento ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , FichaPesquisaId , Id , IdUsuarioContaSistemaRespondido , PerguntaId , RespostaDtRespondido , RespostaFichaPesquisaFichaPesquisaTipo , RespostaFichaPesquisaRespostaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;