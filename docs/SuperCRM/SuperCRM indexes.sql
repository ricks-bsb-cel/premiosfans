;

CREATE  UNIQUE NONCLUSTERED INDEX idxObjType ON dbo.Acao (  ObjType ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.AcaoEventoTipo (  EventoTipo ASC  , IdAcao ASC  )  
	 INCLUDE ( AutoExecutavel ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.AcaoLote (  IdContaSistema ASC  , IdUsuarioContaSistema ASC  , StatusProcessamento ASC  )  
	 INCLUDE ( DtInclusao , Tipo ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.AcaoLote (  IdGuid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

CREATE NONCLUSTERED INDEX idxDtAtualizacaoAuto ON dbo.Alarme (  DtAtualizacaoAuto ASC  )  
	 INCLUDE ( Id , IdSuperEntidade ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.Alarme (  IdContaSistema ASC  , Data ASC  )  
	 INCLUDE ( IdSuperEntidade , Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.Alarme (  IdGuid ASC  )  
	 INCLUDE ( Data , Id , IdSuperEntidade , Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdSuperEntidade ON dbo.Alarme (  IdSuperEntidade ASC  , Data ASC  , Status ASC  )  
	 INCLUDE ( DataUltimoStatus , Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdSuperEntidade2 ON dbo.Alarme (  IdSuperEntidade ASC  , DataUltimoStatus DESC  , Status ASC  )  
	 INCLUDE ( Data , Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxStatus ON dbo.Alarme (  Status ASC  , IdSuperEntidade ASC  , Data ASC  )  
	 INCLUDE ( DataUltimoStatus , Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX nci_wi_Alarme_733F3DA78C252149B385F0B4752A4969 ON dbo.Alarme (  IdContaSistema ASC  , Status ASC  , Data ASC  )  
	 INCLUDE ( IdSuperEntidade ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX Idx2IdInteracaoAutoUltima ON dbo.Atendimento (  IdInteracaoAutoUltima ASC  , StatusAtendimento ASC  )  
	 INCLUDE ( DtInicioAtendimento , Id , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , IdMotivacaoNaoConversaoVenda , idPessoaProspect , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX Idx2IdInteracaoProspectUltima ON dbo.Atendimento (  IdInteracaoProspectUltima ASC  , StatusAtendimento ASC  )  
	 INCLUDE ( DtInicioAtendimento , Id , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , IdMotivacaoNaoConversaoVenda , idPessoaProspect , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX IdxIdInteracaoNegociacaoVendaUltima ON dbo.Atendimento (  idInteracaoNegociacaoVendaUltima ASC  , negociacaoStatus ASC  )  
	 INCLUDE ( Id , idClassificacao , IdContaSistema , IdMotivacaoNaoConversaoVenda , IdUsuarioContaSistemaAtendimento , StatusAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idx2DataFimValidadeAtendimento ON dbo.Atendimento (  DataFimValidadeAtendimento ASC  , Id ASC  )  
	 INCLUDE ( DtInicioAtendimento , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , StatusAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2Id ON dbo.Atendimento (  Id DESC  , IdUsuarioContaSistemaAtendimento ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInicioAtendimento , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idClassificacao , idGrupo , IdGrupoPecaMarketing , IdInteracaoAutoUltima , IdInteracaoProspectUltima , IdInteracaoUsuarioUltima , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idProduto , IdProspeccao , InteracaoUsuarioUltimaDt , RegistroStatus , StatusAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2IdCanalAtendimento ON dbo.Atendimento (  IdCanalAtendimento ASC  , StatusAtendimento ASC  , TipoDirecionamento ASC  )  
	 INCLUDE ( DataFimValidadeAtendimento , DataInicioValidadeAtendimento , DataUltimaInteracaoFila , DtInicioAtendimento , Id , idCampanha , IdCampanhaMarketing , idCanalCriacao , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao , InteracaoUsuarioUltimaDt , QtdInteracaoFila ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2IdCanalCriacao ON dbo.Atendimento (  idCanalCriacao ASC  )  
	 INCLUDE ( Id , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2IdClassificacao ON dbo.Atendimento (  idClassificacao ASC  , IdContaSistema ASC  )  
	 INCLUDE ( ComissaoNegocio , DtInicioAtendimento , Id , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idGrupo , IdGrupoPecaMarketing , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao , StatusAtendimento , ValorNegocio ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2IdGrupo ON dbo.Atendimento (  idGrupo ASC  )  
	 INCLUDE ( Id , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , IdContaSistema , IdGrupoPecaMarketing , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2IdInteracaoUsuarioUltima ON dbo.Atendimento (  IdInteracaoUsuarioUltima ASC  , StatusAtendimento ASC  )  
	 INCLUDE ( DtInicioAtendimento , Id , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , IdMotivacaoNaoConversaoVenda , idPessoaProspect , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2IdMidia ON dbo.Atendimento (  idMidia ASC  , idPeca ASC  )  
	 INCLUDE ( Id , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , IdMotivacaoNaoConversaoVenda , idPessoaProspect , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2IdMotivacaoNaoConversaoVenda ON dbo.Atendimento (  IdMotivacaoNaoConversaoVenda ASC  , StatusAtendimento ASC  )  
	 INCLUDE ( Id , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , idMidia , idPeca , idPessoaProspect , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2IdPeca ON dbo.Atendimento (  idPeca ASC  , idMidia ASC  )  
	 INCLUDE ( Id , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , IdMotivacaoNaoConversaoVenda , idPessoaProspect , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2IdPessoaProspect ON dbo.Atendimento (  idPessoaProspect ASC  , IdContaSistema ASC  )  
	 INCLUDE ( Id , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , idGrupo , IdGrupoPecaMarketing , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao , StatusAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2IdPlantao ON dbo.Atendimento (  idPlantao ASC  )  
	 INCLUDE ( Id , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2IdProduto ON dbo.Atendimento (  idProduto ASC  , StatusAtendimento ASC  )  
	 INCLUDE ( DtInicioAtendimento , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idPlantao , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2IdProspeccao ON dbo.Atendimento (  IdProspeccao ASC  )  
	 INCLUDE ( DataUltimaInteracaoFila , Id , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idPlantao , idProduto , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao , QtdInteracaoFila , StatusAtendimento , TipoDirecionamento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2IdUsuarioContaSistemaAtendimento ON dbo.Atendimento (  IdUsuarioContaSistemaAtendimento ASC  , StatusAtendimento ASC  )  
	 INCLUDE ( idCampanha , IdCanalAtendimento , IdContaSistema , idGrupo , idPessoaProspect ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2IdUsuarioContaSistemaCriacao ON dbo.Atendimento (  idUsuarioContaSistemaCriacao ASC  )  
	 INCLUDE ( Id , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2RegistroStatus ON dbo.Atendimento (  RegistroStatus ASC  , StatusAtendimento ASC  )  
	 INCLUDE ( Id , IdContaSistema , idPessoaProspect ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx3StatusAtendimento ON dbo.Atendimento (  StatusAtendimento ASC  , IdUsuarioContaSistemaAtendimento ASC  , DataFimValidadeAtendimento ASC  )  
	 INCLUDE ( DataInicioValidadeAtendimento , DataUltimaInteracaoFila , dtInclusao , DtInicioAtendimento , Id , IdAlarmeUltimo , IdAlarmeUltimoAtivo , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , IdContaSistema , idGrupo , IdGrupoPecaMarketing , IdInteracaoUsuarioUltima , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idPlantao , idProduto , IdProspeccao , idUsuarioContaSistemaCriacao , QtdInteracaoFila , RegistroStatus ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx4StatusAtendimento ON dbo.Atendimento (  StatusAtendimento ASC  , TipoDirecionamento ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DataFimValidadeAtendimento , DataUltimaInteracaoFila , dtInclusao , DtInicioAtendimento , Id , IdAlarmeUltimo , IdAlarmeUltimoAtivo , idCampanha , IdCampanhaMarketing , IdCanalAtendimento , idCanalCriacao , idClassificacao , idGrupo , IdGrupoPecaMarketing , IdInteracaoUsuarioUltima , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idPlantao , idProduto , IdProspeccao , IdUsuarioContaSistemaAtendimento , idUsuarioContaSistemaCriacao , InteracaoUsuarioUltimaDt , QtdInteracaoFila , RegistroStatus ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxDtInclusao ON dbo.Atendimento (  dtInclusao ASC  , IdUsuarioContaSistemaAtendimento ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInicioAtendimento , idCampanha , IdCanalAtendimento , idClassificacao , idGrupo , IdMotivacaoNaoConversaoVenda , idPessoaProspect ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.Atendimento (  idGuid ASC  )  
	 INCLUDE ( IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdCampanha ON dbo.Atendimento (  idCampanha ASC  , IdContaSistema ASC  , idProduto ASC  )  
	 INCLUDE ( DtInicioAtendimento , idGrupo , idPessoaProspect , IdUsuarioContaSistemaAtendimento , StatusAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdContaSistema1 ON dbo.Atendimento (  IdContaSistema ASC  , DtInicioAtendimento ASC  )  
	 INCLUDE ( dtInclusao , idCampanha , IdCanalAtendimento , idClassificacao , idGrupo , idGuid , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idProduto , IdUsuarioContaSistemaAtendimento , InteracaoUsuarioUltimaDt , StatusAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdContaSistema3 ON dbo.Atendimento (  IdContaSistema ASC  , StatusAtendimento ASC  , TipoDirecionamento ASC  , TipoDirecionamentoStatus ASC  , DataFimValidadeAtendimento ASC  )  
	 INCLUDE ( DataInicioValidadeAtendimento , dtInclusao , DtInicioAtendimento , idCampanha , IdCanalAtendimento , idClassificacao , idGrupo , idGuid , idMidia , IdMotivacaoNaoConversaoVenda , idPeca , idPessoaProspect , idProduto , IdUsuarioContaSistemaAtendimento , InteracaoUsuarioUltimaDt ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdContaSistema4 ON dbo.Atendimento (  IdContaSistema ASC  , IdUsuarioContaSistemaAtendimento ASC  , StatusAtendimento ASC  , idCampanha ASC  , TipoDirecionamento ASC  , idProduto ASC  )  
	 INCLUDE ( DtInicioAtendimento , IdAlarmeUltimoAtivo , IdCanalAtendimento , idGrupo , IdInteracaoUsuarioUltima , idPessoaProspect , InteracaoUsuarioUltimaDt , negociacaoStatus ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdContaSistema5 ON dbo.Atendimento (  IdContaSistema ASC  , RegistroStatus ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdContaSistema6 ON dbo.Atendimento (  IdContaSistema ASC  , IdUsuarioContaSistemaAtendimento ASC  , dtInclusao ASC  )  
	 INCLUDE ( DtInicioAtendimento , idCampanha , idGrupo , idGuid , idPessoaProspect , StatusAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxUnique ON dbo.Atendimento (  idPessoaProspect ASC  , idCampanha ASC  )  
	 INCLUDE ( Id , IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxVersao ON dbo.Atendimento (  versao ASC  , Id ASC  )  
	 INCLUDE ( idCampanha , IdContaSistema , idGrupo , idMidia , idPeca , idPessoaProspect , idProduto ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxVersaoAtendimento ON dbo.Atendimento (  versao ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX nci_wi_Atendimento_1B1EBC8622D8EA6E538B8A56E28EE05F ON dbo.Atendimento (  IdContaSistema ASC  , IdMotivacaoNaoConversaoVenda ASC  , StatusAtendimento ASC  , DtInicioAtendimento ASC  )  
	 INCLUDE ( idCampanha , idGrupo , idGuid , idMidia , idPeca , idPessoaProspect , idProduto , IdUsuarioContaSistemaAtendimento , versao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX nci_wi_Atendimento_9D29D2BBE513DE04AC29B0C563D65915 ON dbo.Atendimento (  IdContaSistema ASC  , StatusAtendimento ASC  , InteracaoUsuarioUltimaDt ASC  )  
	 INCLUDE ( idCampanha , idGrupo , idPessoaProspect , IdUsuarioContaSistemaAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX nci_wi_Atendimento_FA1C81D7F8DEAEC143F3FF553B737AAF ON dbo.Atendimento (  idClassificacao ASC  , IdUsuarioContaSistemaAtendimento ASC  , StatusAtendimento ASC  )  
	 INCLUDE ( ComissaoNegocio , idProduto , ValorNegocio ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX ridx_Atendimento ON dbo.Atendimento (  idCampanha ASC  , TipoDirecionamento ASC  , StatusAtendimento ASC  )  
	 INCLUDE ( DataUltimaInteracaoFila , DtInicioAtendimento , IdAlarmeUltimo , IdAlarmeUltimoAtivo , IdCanalAtendimento , IdContaSistema , IdInteracaoUsuarioUltima , idPessoaProspect , IdProspeccao , QtdInteracaoFila ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxIdAtendimento ON dbo.AtendimentoFilaInteracao (  IdAtendimento ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxIdAtendimento ON dbo.AtendimentoSeguidor (  IdAtendimento ASC  , IdUsuarioContaSistema ASC  , Status ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdGuid ON dbo.AtendimentoSeguidor (  IdGuid ASC  )  
	 INCLUDE ( IdAtendimento , IdUsuarioContaSistema , Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdPessoaProspect ON dbo.AtendimentoSeguidor (  IdPessoaProspect ASC  , IdUsuarioContaSistema ASC  , Status ASC  )  
	 INCLUDE ( Id , IdAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdUsuarioContaSistema ON dbo.AtendimentoSeguidor (  IdUsuarioContaSistema ASC  , IdAtendimento ASC  )  
	 INCLUDE ( Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.AtendimentoSubProduto (  IdAtendimento ASC  , IdProdutoSub ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX IDXIP ON dbo.AutorizacaoIP (  IP ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

CREATE NONCLUSTERED INDEX idxIdUsuarioContaSistema ON dbo.Bookmark (  IdUsuarioContaSistema ASC  , IdContaSistema ASC  )  
	 INCLUDE ( Id , ReadOnlySys , Tipo ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxIdSuperEntidade ON dbo.BookmarkSuperEntidade (  IdSuperEntidade ASC  , IdUsuarioContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.Campanha (  GUID ASC  )  
	 INCLUDE ( IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.Campanha (  IdContaSistema ASC  , Status ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdRegraFidelizacao ON dbo.Campanha (  IdRegraFidelizacao ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxVersao ON dbo.Campanha (  versao ASC  , Id ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idx1 ON dbo.CampanhaAdministrador (  IdCampanha ASC  , IdUsuarioContaSistema ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idx2 ON dbo.CampanhaAdministrador (  IdUsuarioContaSistema ASC  , IdCampanha ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxCanal ON dbo.CampanhaCanal (  IdCanal ASC  , IdCampanha ASC  )  
	 INCLUDE ( CanalPadrao , Id , NumeroMaxAtendimentoSimultaneo , UsarCanalNoAutoEncerrar ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdCampanha ON dbo.CampanhaCanal (  IdCampanha ASC  , IdCanal ASC  )  
	 INCLUDE ( CanalPadrao , Id , NumeroMaxAtendimentoSimultaneo , UsarCanalNoAutoEncerrar ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxUsarCanalNoAutoEncerrar ON dbo.CampanhaCanal (  UsarCanalNoAutoEncerrar ASC  )  
	 INCLUDE ( IdCampanha , IdCanal ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxTipo ON dbo.CampanhaConfiguracao (  Tipo ASC  , Valor ASC  , IdCampanha ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxTipo2 ON dbo.CampanhaConfiguracao (  Tipo ASC  , ValorInt ASC  , IdCampanha ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxUniqueIdCampanha ON dbo.CampanhaConfiguracao (  IdCampanha ASC  , Tipo ASC  )  
	 INCLUDE ( Valor , ValorInt ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.CampanhaFichaPesquisa (  IdCampanha ASC  , FichaPesquisaTipo ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idx1 ON dbo.CampanhaFichaPesquisa (  IdCampanha ASC  , IdFichaPesquisa ASC  , FichaPesquisaTipo ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX IDX ON dbo.CampanhaFichaPesquisaPerguntaProdutoSub (  IdCampanhaFichaPesquisa ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.CampanhaFichaPesquisaPerguntaProdutoSub (  IdCampanhaFichaPesquisa ASC  , IdProdutoSub ASC  , IdPergunta ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

CREATE NONCLUSTERED INDEX idxStatus ON dbo.CampanhaGrupo (  Status ASC  , IdGrupo ASC  )  
	 INCLUDE ( IdCampanha ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxUniqueIdCampanha ON dbo.CampanhaGrupo (  IdCampanha ASC  , IdGrupo ASC  )  
	 INCLUDE ( Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxUniqueIdGrupo ON dbo.CampanhaGrupo (  IdGrupo ASC  , IdCampanha ASC  )  
	 INCLUDE ( Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.CampanhaMarketing (  IdContaSistema ASC  , Nome ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.Canal (  GUID ASC  )  
	 INCLUDE ( Id , IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.Canal (  IdContaSistema ASC  , Tipo ASC  , Status ASC  )  
	 INCLUDE ( Id , NumeroMaxAtendimentoSimultaneo ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxTipo ON dbo.Canal (  Tipo ASC  , Status ASC  , DtProximoExpurgoChat ASC  )  
	 INCLUDE ( Id , IdContaSistema , Nome , TimeExpurgoChat ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX nci_wi_Canal_0DA118E70FA700A968F640AC564F304F ON dbo.Canal (  Tipo ASC  )  
	 INCLUDE ( DtInclusao , DtProximoExpurgoChat , DtUltimoExpurgoChatExecutado , GUID , HabilitarPrevisaoDeMensagem , IdCanalTransbordo , IdContaSistema , Meio , MensagemAutomatica , Nome , NumeroMaxAtendimentoSimultaneo , Status , TempoMaxInicioAtendimento , TimeExpurgoChat , TipoTempoMaxInicioAtendimento , versao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX nci_wi_CanalExpurgo_6E4A7B92E65B8C633A2179E3E7CFBDEA ON dbo.CanalExpurgo (  DiaSemanaExpurgo ASC  , TimeExpurgo ASC  , IdCanal ASC  )  
	 INCLUDE ( Acao , DtInclusao , DtUltimoExpurgoExecutado , DtUltimoExpurgoExecutadoFull , DtValidade , IdGuid , IdUsuarioContaSistema , Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.CanalInteracaoTipo (  IdCanal ASC  , IdInteracaoTipo ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.Card (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.Classificacao (  IdContaSistema ASC  , Tipo ASC  , Valor ASC  , Valor2 ASC  )  
	 INCLUDE ( Id , IdGuid , Ordem , Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxUnique ON dbo.Classificacao (  IdGuid ASC  )  
	 INCLUDE ( Id , IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.ContaSistema (  Guid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxGuidCorrex ON dbo.ContaSistema (  GuidCorrex ASC  )  
	 WHERE  ([GuidCorrex] IS NOT NULL)
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.ContaSistemaConfiguracao (  IdContaSistema ASC  , Tipo ASC  )  
	 INCLUDE ( Id , Status , Valor , ValorInt ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

CREATE NONCLUSTERED INDEX idxContaSistema ON dbo.ContaSistemaHost (  IdContaSistema ASC  , Host ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxUnique ON dbo.ContaSistemaHost (  Host ASC  )  
	 WHERE  ([TIPO]<>'APP')
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX nci_wi_ContaSistemaHost_175581158A671475DDF5DF37839F3ABF ON dbo.ContaSistemaHost (  Host ASC  , IdContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX IDXCONTASISTEMA ON dbo.ContaSistemaLog (  IdContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

CREATE  UNIQUE NONCLUSTERED INDEX idxContaSistemaTipoUnique ON dbo.ContaSistemaTelefoniaConf (  IdContaSistema ASC  , Tipo ASC  )  
	 INCLUDE ( Ativo , IdTransportadoraContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxGuidUnique ON dbo.ContaSistemaTelefoniaConf (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.Dashboard (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.DashboardCard (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxUnique ON dbo.DashboardCard (  IdCard ASC  , IdDashboard ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idx1 ON dbo.DbLocalidadeBairro (  IdCidade ASC  )  
	 INCLUDE ( Id , Nome , NomeAbreviado , NomeOficial ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2 ON dbo.DbLocalidadeBairro (  IdCidade ASC  , NomeOficial ASC  , Nome ASC  , NomeAbreviado ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx3 ON dbo.DbLocalidadeBairro (  NomeOficial ASC  , IdCidade ASC  )  
	 INCLUDE ( Id , Nome , NomeAbreviado ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx4 ON dbo.DbLocalidadeBairro (  Nome ASC  , IdCidade ASC  )  
	 INCLUDE ( Id , NomeAbreviado , NomeOficial ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx5 ON dbo.DbLocalidadeBairro (  NomeAbreviado ASC  , IdCidade ASC  )  
	 INCLUDE ( Id , Nome , NomeOficial ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

;

;

CREATE NONCLUSTERED INDEX idxCEP ON dbo.DbLocalidadeCEPLogradouro (  CEP ASC  , IdBairro ASC  )  
	 INCLUDE ( ID ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdBairro ON dbo.DbLocalidadeCEPLogradouro (  IdBairro ASC  , CEP ASC  )  
	 INCLUDE ( ID ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxUniqueCEP ON dbo.DbLocalidadeCEPLogradouro (  CEP ASC  )  
	 INCLUDE ( IdBairro ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idx1 ON dbo.DbLocalidadeCidade (  UF ASC  , Nome ASC  , NomeAbreviado ASC  )  
	 INCLUDE ( Id , Tipo ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2 ON dbo.DbLocalidadeCidade (  UF ASC  , NomeAbreviado ASC  , Nome ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx3 ON dbo.DbLocalidadeCidade (  NomeAbreviado ASC  , Nome ASC  , UF ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx4 ON dbo.DbLocalidadeCidade (  NomeAbreviado ASC  , UF ASC  , Nome ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx5 ON dbo.DbLocalidadeCidade (  Nome ASC  , NomeAbreviado ASC  , UF ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx6 ON dbo.DbLocalidadeCidade (  Nome ASC  , UF ASC  , NomeAbreviado ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idx1 ON dbo.DbLocalidadeUF (  Sigla ASC  )  
	 INCLUDE ( Nome ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX IDXATIVIDADE ON dbo.Email (  IdInteracao ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

;

CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.EnrichPersonDataSource (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxTipo ON dbo.EnrichPersonDataSource (  Tipo ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxIdEnrichPerson ON dbo.EnrichPersonEnrichPersonDataSource (  IdEnrichPerson ASC  , IdEnrichPersonDataSource ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.EnrichPersonEnrichPersonDataSource (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxIdIdEnrichPerson ON dbo.EnrichPersonLog (  IdEnrichPerson ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxIdEnrichPerson ON dbo.EnrichPersonQueryParam (  IdEnrichPerson ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.EnrichPersonQueryParam (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxValue ON dbo.EnrichPersonQueryParam (  Value ASC  , ValueType ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxIdAtendimento ON dbo.EnrichPersonSolicitante (  IdAtendimento ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdEnrichPerson ON dbo.EnrichPersonSolicitante (  IdEnrichPerson ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.EnrichPersonSolicitante (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdPessoaProspect ON dbo.EnrichPersonSolicitante (  IdPessoaProspect ASC  , IdUsuarioContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxIdEnrichPersonSolicitante ON dbo.EnrichPersonSolicitanteEnrichPersonDataSource (  IdEnrichPersonSolicitante ASC  , IdEnrichPersonDataSource ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.EnrichPersonSolicitanteEnrichPersonDataSource (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxGrupoProcessamento ON dbo.Evento (  GrupoProcessamento ASC  , Processado ASC  , Status ASC  )  
	 INCLUDE ( DtValidadeInicio , HrValidadeProcessamentoFim , HrValidadeProcessamentoInicio , ObjAcaoType , ObjTipo , QtdTentativaProcessamento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxProcessado ON dbo.EventoPre (  Processado ASC  , Id ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idx1 ON dbo.EventoTipo (  Tipo ASC  , Status ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX IDXIDCONTASISTEMA ON dbo.FichaPesquisa (  IdContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.FichaPesquisaTipo (  IdFichaPesquisa ASC  , Tipo ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.Gatilho (  IdContaSistema ASC  , IdCampanha ASC  , EventoTipo ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxEventoTipo ON dbo.Gatilho (  EventoTipo ASC  , Status ASC  , DtUltimaExecucao ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.GatilhoAcao (  IdGatilho ASC  , IdAcao ASC  )  
	 INCLUDE ( GatilhoAcaoFiltroHashSHA1 ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxIdAcao ON dbo.GatilhoAcao (  IdAcao ASC  , IdGatilho ASC  )  
	 INCLUDE ( GatilhoAcaoFiltroHashSHA1 ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX IDX1 ON dbo.GatilhoExecucao (  IdGatilho ASC  , IdAcao ASC  , Status ASC  , CodigoIdentificadorStr ASC  , GatilhoFiltroHashSHA1 ASC  , GatilhoAcaoFiltroHashSHA1 ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX IDX2 ON dbo.GatilhoExecucao (  IdGatilho ASC  , IdAcao ASC  , Status ASC  , CodigoIdentificadorInt ASC  , GatilhoFiltroHashSHA1 ASC  , GatilhoAcaoFiltroHashSHA1 ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX IDX3 ON dbo.GatilhoExecucao (  IdGatilho ASC  , GatilhoFiltroHashSHA1 ASC  , GatilhoAcaoFiltroHashSHA1 ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX IDX4 ON dbo.GatilhoExecucao (  Status ASC  , DtValidade ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX IDX5 ON dbo.GatilhoExecucao (  StrGuid ASC  )  
	 INCLUDE ( Id , Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idx6 ON dbo.GatilhoExecucao (  DtValidade ASC  , Status ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxCodigo ON dbo.Grupo (  Codigo ASC  , IdContaSistema ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxContaSistema ON dbo.Grupo (  IdContaSistema ASC  , Padrao ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxId ON dbo.Grupo (  Id ASC  , IdGuid ASC  , IdContaSistema ASC  )  
	 INCLUDE ( Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdGuid ON dbo.Grupo (  IdGuid ASC  )  
	 INCLUDE ( Id , IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxNome ON dbo.Grupo (  Nome ASC  )  
	 INCLUDE ( Id , IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxStatus ON dbo.Grupo (  Status ASC  , IdContaSistema ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxVersao ON dbo.Grupo (  versao ASC  , Id ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX nci_wi_Grupo_98425FF6A6CDA6C6513D777223CA9DD3 ON dbo.Grupo (  IdTag ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.GrupoHierarquia (  IdGrupoSuperior ASC  , IdGrupoInferior ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxIdGrupoInferior ON dbo.GrupoHierarquia (  IdGrupoInferior ASC  )  
	 INCLUDE ( IdGrupoSuperior ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.GrupoHierarquiaUsuarioContaSistema (  IdContaSistema ASC  , IdUsuarioContaSistema ASC  )  
	 INCLUDE ( IdGrupo ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdGrupo ON dbo.GrupoHierarquiaUsuarioContaSistema (  IdGrupo ASC  , IdUsuarioContaSistema ASC  )  
	 INCLUDE ( Id , IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdUsuarioContaSistema ON dbo.GrupoHierarquiaUsuarioContaSistema (  IdUsuarioContaSistema ASC  , IdGrupo ASC  , IdContaSistema ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.GrupoPecaMarketing (  IdContaSistema ASC  , Nome ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.GrupoSuperior (  IdGrupo ASC  , IdGrupoSuperior ASC  , DtFim ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxImportacaoValidacaoTempUsuarioContaSistema ON dbo.ImportacaoValidacaoTemp (  IdContaSistema ASC  , IdUsuarioContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxidxImportacaoValidacaoTempUsuarioContaSistemaIdGuid ON dbo.ImportacaoValidacaoTemp (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

CREATE  UNIQUE NONCLUSTERED INDEX idxGuidUnique ON dbo.IntegraLeads (  IdGuid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdentificadorKey ON dbo.IntegraLeads (  IdentificadorKey ASC  )  
	 INCLUDE ( IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.IntegracaoRestricao (  IdGuid ASC  )  
	 INCLUDE ( IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxValor ON dbo.IntegracaoRestricao (  Valor ASC  , ValorTipo ASC  , Tipo ASC  )  
	 INCLUDE ( IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxIdentificador ON dbo.IntegradoraExterna (  Identificador ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxNome ON dbo.IntegradoraExterna (  Nome ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxStrKey ON dbo.IntegradoraExterna (  StrKey ASC  , Status ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX IDX1 ON dbo.IntegradoraExternaContaSistema (  IdContaSistema ASC  , IdIntegradoraExterna ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.IntegradoraExternaContaSistema (  IdIntegradoraExterna ASC  , IdContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

CREATE NONCLUSTERED INDEX idxDtInclusao ON dbo.Interacao (  DtInclusao DESC  , IdInteracaoTipo ASC  )  
	 INCLUDE ( IdContaSistema , IdSuperEntidade ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxDtInclusao2 ON dbo.Interacao (  DtInclusao ASC  , DtInteracao ASC  , DtConclusao ASC  )  
	 INCLUDE ( IdContaSistema , IdInteracaoTipo , IdSuperEntidade , versao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxDtInteracao ON dbo.Interacao (  DtInteracao DESC  , IdSuperEntidade ASC  )  
	 INCLUDE ( IdContaSistema , IdInteracaoTipo ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdAlarmeUnique ON dbo.Interacao (  IdAlarme ASC  )  
	 INCLUDE ( IdContaSistema , IdInteracaoTipo , IdSuperEntidade , IdUsuarioContaSistema ) 
	 WHERE  ([IdAlarme] IS NOT NULL)
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.Interacao (  IdContaSistema ASC  , IdSuperEntidade ASC  )  
	 INCLUDE ( DtInclusao , Id , IdAlarme , IdInteracaoParent , IdInteracaoTipo , IdUsuarioContaSistema , InteracaoAtorPartida , ObjTipoSub , Tipo , versao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuidUnique ON dbo.Interacao (  IdGuid ASC  )  
	 INCLUDE ( IdContaSistema , IdInteracaoTipo , IdSuperEntidade ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdInteracaoMarketing ON dbo.Interacao (  IdInteracaoMarketing ASC  , IdSuperEntidade ASC  )  
	 INCLUDE ( IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdInteracaoParent ON dbo.Interacao (  IdInteracaoParent ASC  , IdSuperEntidade ASC  )  
	 INCLUDE ( IdContaSistema ) 
	 WHERE  ([IdInteracaoParent] IS NOT NULL)
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdInteracaoTipo2 ON dbo.Interacao (  IdInteracaoTipo ASC  , DtInclusao DESC  , DtInteracao DESC  , DtConclusao DESC  )  
	 INCLUDE ( Id , IdContaSistema , IdSuperEntidade , versao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdSuperEntidade ON dbo.Interacao (  IdSuperEntidade ASC  , Tipo ASC  , ObjTipoSub ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , Id , IdAlarme , IdContaSistema , IdInteracaoParent , IdInteracaoTipo , IdUsuarioContaSistema , InteracaoAtorPartida , versao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxVersao ON dbo.Interacao (  versao ASC  , Id ASC  )  
	 INCLUDE ( IdInteracaoTipo , IdSuperEntidade ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

CREATE NONCLUSTERED INDEX idxIdSuperEntidade ON dbo.InteracaoObj (  IdSuperEntidade ASC  , ObjTipoSub ASC  )  
	 INCLUDE ( IdContaSistema , JSONClassificacaoId , ObjTipo , ObjVersao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.InteracaoTipo (  IdContaSistema ASC  , Status ASC  )  
	 INCLUDE ( Id , Mostrar , Sistema , Tipo , Valor , ValorAbreviado ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxTipo ON dbo.InteracaoTipo (  Tipo ASC  , IdContaSistema ASC  )  
	 INCLUDE ( Id , Status , Valor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxUnique ON dbo.InteracaoTipo (  IdGuid ASC  )  
	 INCLUDE ( Id , IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX nci_wi_InteracaoTipo_A54BC60B73E134F22BD0880473958C83 ON dbo.InteracaoTipo (  Tipo ASC  )  
	 INCLUDE ( Valor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.InteracaoTipoAtorPartida (  IdInteracaoTipo ASC  , InteracaoAtorPartida ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

CREATE  UNIQUE NONCLUSTERED INDEX idxIdInteracaoUnique ON dbo.Ligacao (  IdInteracao ASC  )  
	 INCLUDE ( Id , IdRemessa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdRemessa ON dbo.Ligacao (  IdRemessa ASC  , IdInteracao ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

CREATE NONCLUSTERED INDEX idx2DtInclusao ON dbo.LogAcoes (  DtInclusao ASC  , IdContaSistema ASC  )  
	 INCLUDE ( IdUsuarioContaSistemaExecutou , IdUsuarioContaSistemaImpactou , Tipo , TipoSub ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2IdUsuarioContaSistemaExecutou ON dbo.LogAcoes (  IdUsuarioContaSistemaExecutou ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , IdUsuarioContaSistemaImpactou , Tipo , TipoSub ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2IdUsuarioContaSistemaImpactou ON dbo.LogAcoes (  IdUsuarioContaSistemaImpactou ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , IdUsuarioContaSistemaExecutou , Tipo , TipoSub ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2Tipo ON dbo.LogAcoes (  Tipo ASC  , IdContaSistema ASC  , TipoSub ASC  , DtInclusao ASC  )  
	 INCLUDE ( IdUsuarioContaSistemaExecutou , IdUsuarioContaSistemaImpactou ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxContaSistema ON dbo.LogAcoes (  IdContaSistema ASC  , DtInclusao ASC  )  
	 INCLUDE ( Id , IdUsuarioContaSistemaExecutou , IdUsuarioContaSistemaImpactou , Tipo , TipoSub ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.LogAcoes (  IdGuid ASC  )  
	 INCLUDE ( IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 80   ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX IDX ON dbo.MailMask (  Codigo ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

;

;

;

;

CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.Midia (  GUID ASC  )  
	 INCLUDE ( IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.Midia (  IdContaSistema ASC  , Status ASC  , Publica ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdIntegradoraExterna ON dbo.Midia (  IdIntegradoraExterna ASC  )  
	 INCLUDE ( Id , IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxNome ON dbo.Midia (  Nome ASC  , IdContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxVersao ON dbo.Midia (  versao ASC  , Id ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX nci_wi_Midia_BF430F456F4A2A1A9A78D44E3B12F43C ON dbo.Midia (  IdContaSistema ASC  , Publica ASC  , Status ASC  )  
	 INCLUDE ( AutoInclusao , DtAtualizacao , DtInclusao , GUID , IdIntegradoraExterna , IdMidiaTipo , Nome , Obs , versao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX IDX1 ON dbo.MidiaInvestimento (  IdMidia ASC  , DtInicio ASC  , DtFim ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

CREATE  UNIQUE NONCLUSTERED INDEX idxUnique ON dbo.MidiaTipo (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idxCodigo ON dbo.ModuloSistema (  Codigo ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.ModuloSistemaContaSistema (  IdContaSistema ASC  , IdModuloSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idxIdModuloSistema ON dbo.ModuloSistemaContaSistema (  IdModuloSistema ASC  , IdContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX IDXCONTASISTEMA ON dbo.Motivacao (  IdContaSistema ASC  , IdGuid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.Motivacao (  IdGuid ASC  )  
	 INCLUDE ( IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX IDXSUPERENTIDADE ON dbo.Nota (  IdSuperEntidade ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX IDXUSUARIOCONTASISTEMA ON dbo.Nota (  IdUsuarioContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX IDXGUID ON dbo.NotificacaoGlobal (  StrGuid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idx1 ON dbo.NotificacaoGlobal (  AvisoStatus DESC  , Id DESC  , IdUsuarioContaSistemaResponsavel ASC  , Status ASC  , DtValidade ASC  )  
	 INCLUDE ( IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2 ON dbo.NotificacaoGlobal (  Status ASC  , Identificacao ASC  , TipoNotificacao ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx3 ON dbo.NotificacaoGlobal (  CodigoIdentificadorEntidade ASC  , CodigoIdentificadorInt ASC  , ReferenciaEntidade ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idx2DtOportunidade ON dbo.OportunidadeNegocio (  DtOportunidade ASC  )  
	 INCLUDE ( IdAtendimento , IdOportunidadeNegocioTipo , IdPessoaProspect , IdProduto , IdProdutoSub , IdSuperEntidade , IdUsuarioContaSistema , IdUsuarioContaSistemaRegistrou ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2IdAtendimento ON dbo.OportunidadeNegocio (  IdAtendimento ASC  )  
	 INCLUDE ( IdOportunidadeNegocioTipo , IdPessoaProspect , IdProduto , IdProdutoSub , IdSuperEntidade , IdUsuarioContaSistema , IdUsuarioContaSistemaRegistrou ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2IdOportunidadeNegocioTipo ON dbo.OportunidadeNegocio (  IdOportunidadeNegocioTipo ASC  )  
	 INCLUDE ( IdAtendimento , IdPessoaProspect , IdProduto , IdProdutoSub , IdSuperEntidade , IdUsuarioContaSistema , IdUsuarioContaSistemaRegistrou ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2IdPessoaProspect ON dbo.OportunidadeNegocio (  IdPessoaProspect ASC  )  
	 INCLUDE ( IdAtendimento , IdOportunidadeNegocioTipo , IdProduto , IdProdutoSub , IdSuperEntidade , IdUsuarioContaSistema , IdUsuarioContaSistemaRegistrou ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2IdProduto ON dbo.OportunidadeNegocio (  IdProduto ASC  )  
	 INCLUDE ( IdAtendimento , IdOportunidadeNegocioTipo , IdPessoaProspect , IdProdutoSub , IdSuperEntidade , IdUsuarioContaSistema , IdUsuarioContaSistemaRegistrou ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2IdProdutoSub ON dbo.OportunidadeNegocio (  IdProdutoSub ASC  )  
	 INCLUDE ( IdAtendimento , IdOportunidadeNegocioTipo , IdPessoaProspect , IdProduto , IdSuperEntidade , IdUsuarioContaSistema , IdUsuarioContaSistemaRegistrou ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2IdSuperEntidade ON dbo.OportunidadeNegocio (  IdSuperEntidade ASC  )  
	 INCLUDE ( IdAtendimento , IdOportunidadeNegocioTipo , IdPessoaProspect , IdProduto , IdProdutoSub , IdUsuarioContaSistema , IdUsuarioContaSistemaRegistrou ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2IdUsuarioContaSistema ON dbo.OportunidadeNegocio (  IdUsuarioContaSistema ASC  )  
	 INCLUDE ( IdAtendimento , IdOportunidadeNegocioTipo , IdPessoaProspect , IdProduto , IdProdutoSub , IdSuperEntidade , IdUsuarioContaSistemaRegistrou ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2IdUsuarioContaSistemaRegistrou ON dbo.OportunidadeNegocio (  IdUsuarioContaSistemaRegistrou ASC  )  
	 INCLUDE ( IdAtendimento , IdOportunidadeNegocioTipo , IdPessoaProspect , IdProduto , IdProdutoSub , IdSuperEntidade , IdUsuarioContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX IDXCONTASISTEMA ON dbo.OportunidadeNegocioTipo (  IdContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.OportunidadeNegocioTipo (  Nome ASC  , IdContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

CREATE NONCLUSTERED INDEX idxGUID ON dbo.Peca (  GUID ASC  , IdMidia ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdMidia ON dbo.Peca (  IdMidia ASC  , Nome ASC  )  
	 INCLUDE ( Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxNome ON dbo.Peca (  Nome ASC  , IdMidia ASC  )  
	 INCLUDE ( Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxVersao ON dbo.Peca (  versao ASC  , Id ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.PendenciaProcessamento (  IdContaSistema ASC  , IdUsuarioContaSistema ASC  , Status ASC  , DtPreProcessado ASC  )  
	 INCLUDE ( Tipo ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.PendenciaProcessamento (  IdGuid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxPendenciaHashSHA1 ON dbo.PendenciaProcessamento (  PendenciaHashSHA1 ASC  , Finalizado ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxPreProcessado ON dbo.PendenciaProcessamento (  PreProcessado ASC  , Processado ASC  , Status ASC  )  
	 INCLUDE ( DtPreProcessado , DtProcessado , Finalizado , IdUsuarioContaSistema , QtdAtualizacao , QtdTentativaProcessamento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxStatus ON dbo.PendenciaProcessamento (  Status ASC  , PreProcessado ASC  , DtInclusao ASC  , DtValidadeInicioProcessamento ASC  )  
	 INCLUDE ( IdContaSistema , IdGuidContaSistema , IdGuidUsuarioContaSistema , IdUsuarioContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxStatus2 ON dbo.PendenciaProcessamento (  Status ASC  , PreProcessado ASC  , Processado ASC  , Finalizado ASC  )  
	 INCLUDE ( DtPreProcessado , IdContaSistema , IdGuidContaSistema , IdGuidUsuarioContaSistema , IdUsuarioContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxIdPendenciaProcessamento ON dbo.PendenciaProcessamentoLog (  IdPendenciaProcessamento ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

CREATE NONCLUSTERED INDEX idx1 ON dbo.PerfilUsuario (  idContaSistema ASC  , Padrao ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idx1 ON dbo.Pergunta (  IdFichaPesquisa ASC  , Obrigatorio ASC  , Status ASC  )  
	 INCLUDE ( Id , Tipo ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxValor ON dbo.PesquisaNPSAdjetivo (  Valor ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxValor ON dbo.PesquisaNPSPalavraIgnore (  Valor ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxValor ON dbo.PesquisaNPSPalavraNaoIgnore (  Valor ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxEmail ON dbo.Pessoa (  Email ASC  , Nome ASC  )  
	 INCLUDE ( Guid , Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.Pessoa (  Guid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxNome ON dbo.Pessoa (  Nome ASC  , Email ASC  )  
	 INCLUDE ( Guid , Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

;

CREATE  UNIQUE NONCLUSTERED INDEX idx1 ON dbo.PessoaProfissao (  IdContaSistema ASC  , Nome ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxCodigo ON dbo.PessoaProspect (  Codigo ASC  , Nome ASC  )  
	 INCLUDE ( Id , IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.PessoaProspect (  IdContaSistema ASC  , Id ASC  )  
	 INCLUDE ( Codigo , Nome ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdUsuarioContaSistemaAnonimizado ON dbo.PessoaProspect (  IdUsuarioContaSistemaAnonimizado ASC  )  
	 INCLUDE ( DtAnonimizacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxNome ON dbo.PessoaProspect (  Nome ASC  , Codigo ASC  )  
	 INCLUDE ( Id , IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxNome2 ON dbo.PessoaProspect (  IdContaSistema ASC  , Nome ASC  , Codigo ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxRegistroStatus ON dbo.PessoaProspect (  RegistroStatus ASC  )  
	 INCLUDE ( IdContaSistema , RegistroStatusIdUsuarioContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxVersao ON dbo.PessoaProspect (  versao ASC  , Id ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX IDXPESSOAPROSPECT ON dbo.PessoaProspectDadosGerais (  IdPessoaProspect ASC  , Tipo ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX IDX1 ON dbo.PessoaProspectDocumento (  IdPessoaProspect ASC  , Doc ASC  , TipoDoc ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idx2 ON dbo.PessoaProspectDocumento (  TipoDoc ASC  , Doc ASC  , IdPessoaProspect ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx3 ON dbo.PessoaProspectDocumento (  Doc ASC  , TipoDoc ASC  , IdPessoaProspect ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx4 ON dbo.PessoaProspectDocumento (  IdPessoaProspect ASC  , TipoDoc ASC  )  
	 INCLUDE ( Doc , Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxUnique ON dbo.PessoaProspectDocumento (  IdGuid ASC  )  
	 INCLUDE ( Id , IdPessoaProspect ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxEmail ON dbo.PessoaProspectEmail (  Email ASC  , IdPessoaProspect ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.PessoaProspectEmail (  IdGuid ASC  )  
	 INCLUDE ( Id , IdPessoaProspect ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdPessoaProspect ON dbo.PessoaProspectEmail (  IdPessoaProspect ASC  , Email ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX IDXPESSOAPROSPECT ON dbo.PessoaProspectEndereco (  IdPessoaProspect ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idx1 ON dbo.PessoaProspectEndereco (  IdPessoaProspect ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxUnique ON dbo.PessoaProspectEndereco (  IdGuid ASC  )  
	 INCLUDE ( Id , IdPessoaProspect ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.PessoaProspectFidelizado (  IdPessoaProspect ASC  , DtFimFidelizacao ASC  , IdCampanha ASC  )  
	 INCLUDE ( Id , IdUsuarioContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idx2DtFimFidelizacao ON dbo.PessoaProspectFidelizado (  DtFimFidelizacao ASC  , IdCampanha ASC  )  
	 INCLUDE ( DtInicioFidelizacao , Id , IdGrupo , IdPessoaProspect , IdRegraFidelizacao , IdUsuarioContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxDtFimFidelizacao ON dbo.PessoaProspectFidelizado (  DtFimFidelizacao ASC  , IdPessoaProspect ASC  , IdCampanha ASC  , IdRegraFidelizacao ASC  )  
	 INCLUDE ( Id , IdUsuarioContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdPessoaProspect ON dbo.PessoaProspectFidelizado (  IdPessoaProspect ASC  , IdCampanha ASC  , DtFimFidelizacao ASC  )  
	 INCLUDE ( DtInicioFidelizacao , IdGrupo , IdRegraFidelizacao , IdUsuarioContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdUsuarioContaSistema ON dbo.PessoaProspectFidelizado (  IdUsuarioContaSistema ASC  , IdPessoaProspect ASC  )  
	 INCLUDE ( DtFimFidelizacao , DtInicioFidelizacao , IdCampanha , IdGrupo , IdRegraFidelizacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxRegraFidelizacao ON dbo.PessoaProspectFidelizado (  IdRegraFidelizacao ASC  , IdCampanha ASC  )  
	 INCLUDE ( DtFimFidelizacao , Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxContaSistema ON dbo.PessoaProspectImportacao (  idContaSistema ASC  , Status ASC  , DtInclusao ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxStatus ON dbo.PessoaProspectImportacao (  Status ASC  , DtInclusao ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxIdPessoaProspectImportacao ON dbo.PessoaProspectImportacaoTemp (  IdPessoaProspectImportacao ASC  , Status ASC  , SysValido ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX nci_wi_PessoaProspectImportacaoTemp_2DF03E5FF7CBEC080CB394C30AA779F7 ON dbo.PessoaProspectImportacaoTemp (  IdPessoaProspectImportacao ASC  )  
	 INCLUDE ( DtUltimoStatus , ErroInternoObs , NovoProspect , Obj , ObjTipo , QtdTentativa , Status , SysErroColunas , SysErroObs , SysValido , SysValidoEndereco ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxContaSistema ON dbo.PessoaProspectIntegracaoLog (  IdContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxDtInclusao ON dbo.PessoaProspectIntegracaoLog (  DtInclusao ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdAtendimento ON dbo.PessoaProspectIntegracaoLog (  IdAtendimento ASC  , KeyMaxVendas ASC  , KeyExterno ASC  )  
	 INCLUDE ( Id , KeyMaxVendasCookie ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdInteracao ON dbo.PessoaProspectIntegracaoLog (  IdInteracao ASC  , IdAtendimento ASC  )  
	 INCLUDE ( Id , IdCampanha , IdCanal , IdContaSistema , IdIntegradoraExterna , IdMidia , IdProduto ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxKeyExterno ON dbo.PessoaProspectIntegracaoLog (  KeyExterno ASC  , IdAtendimento ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxKeyMaxVendas ON dbo.PessoaProspectIntegracaoLog (  KeyMaxVendas ASC  )  
	 INCLUDE ( Id , IdAtendimento , KeyMaxVendasCookie ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxKeyMaxVendasCookie ON dbo.PessoaProspectIntegracaoLog (  KeyMaxVendasCookie ASC  )  
	 INCLUDE ( Id , IdAtendimento , KeyMaxVendas ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxProspectIP ON dbo.PessoaProspectIntegracaoLog (  ProspectIP ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.PessoaProspectOrigem (  IdGuid ASC  )  
	 INCLUDE ( Id , idContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdPessoaProspectImportacao ON dbo.PessoaProspectOrigem (  IdPessoaProspectImportacao ASC  , idContaSistema ASC  )  
	 INCLUDE ( Nome ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxidContaSistema ON dbo.PessoaProspectOrigem (  idContaSistema ASC  , Nome ASC  )  
	 INCLUDE ( IdPessoaProspectImportacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxIdAtendimento ON dbo.PessoaProspectOrigemPessoaProspect (  IdAtendimento ASC  , IdPessoaProspect ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdPessoaProspect ON dbo.PessoaProspectOrigemPessoaProspect (  IdPessoaProspect ASC  , IdPessoaProspectOrigem ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdPessoaProspectImportacaoTemp ON dbo.PessoaProspectOrigemPessoaProspect (  IdPessoaProspectImportacaoTemp ASC  )  
	 INCLUDE ( Id , IdPessoaProspect ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdPessoaProspectOrigem ON dbo.PessoaProspectOrigemPessoaProspect (  IdPessoaProspectOrigem ASC  )  
	 INCLUDE ( Id , IdAtendimento , IdPessoaProspect ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX nci_wi_PessoaProspectPerfil_21FC2186AD6A36EC00CE8DD9264F9FF9 ON dbo.PessoaProspectPerfil (  IdPessoaProspect ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxIdPessoaProspect ON dbo.PessoaProspectPrefereciaFidelizacao (  IdPessoaProspect ASC  , DtInclusao ASC  )  
	 INCLUDE ( Id , IdPessoaProspectImportacao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdPessoaProspectImportacao ON dbo.PessoaProspectPrefereciaFidelizacao (  IdPessoaProspectImportacao ASC  , DtInclusao ASC  )  
	 INCLUDE ( Id , IdPessoaProspect ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX IDXGUID ON dbo.PessoaProspectTag (  IdGuid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idxIdPessoaProspect ON dbo.PessoaProspectTag (  IdPessoaProspect ASC  , IdTag ASC  )  
	 INCLUDE ( Id , IdGuid ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdTag ON dbo.PessoaProspectTag (  IdTag ASC  , IdPessoaProspect ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxIdPessoaProspect ON dbo.PessoaProspectTelefone (  IdPessoaProspect ASC  , Telefone ASC  )  
	 INCLUDE ( DDD ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxTelefone ON dbo.PessoaProspectTelefone (  Telefone ASC  , DDD ASC  )  
	 INCLUDE ( IdPessoaProspect ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxUnique ON dbo.PessoaProspectTelefone (  IdGuid ASC  )  
	 INCLUDE ( Id , IdPessoaProspect ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxIdPessoa ON dbo.PessoaTelefone (  IdPessoa ASC  )  
	 INCLUDE ( DDD , Id , Preferencial , Telefone ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxDtInicioValidade ON dbo.Plantao (  DtInicioValidade ASC  , DtFimValidade ASC  , Status ASC  )  
	 INCLUDE ( Id , IdCampanha ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdCampanha ON dbo.Plantao (  IdCampanha ASC  , DtInicioValidade ASC  , DtFimValidade ASC  , Status ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxStatus ON dbo.Plantao (  Status ASC  , DtFimValidade ASC  )  
	 INCLUDE ( DtInicioValidade , IdCampanha ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxDtInicio ON dbo.PlantaoHorario (  DtInicio ASC  , DtFim ASC  , Status ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdPlantao ON dbo.PlantaoHorario (  IdPlantao ASC  , Status ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX nci_wi_PlantaoHorario_D79523595A804F480265B0B357E90DD0 ON dbo.PlantaoHorario (  DtFim ASC  )  
	 INCLUDE ( DtInicio , IdPlantao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX nci_wi_PlantaoHorario_EB15864B2F3C15602392F94287391B68 ON dbo.PlantaoHorario (  Status ASC  , DtFim ASC  )  
	 INCLUDE ( DtInicio , IdPlantao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idContaSistema ON dbo.PoliticaDePrivacidade (  IdContaSistema ASC  , Tipo ASC  )  
	 INCLUDE ( Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.PoliticaDePrivacidade (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxIdPessoaProspect ON dbo.PoliticaDePrivacidadePessoaProspect (  IdPessoaProspect ASC  , IdPoliticaDePrivacidade ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdPoliticaDePrivacidade ON dbo.PoliticaDePrivacidadePessoaProspect (  IdPoliticaDePrivacidade ASC  , IdPessoaProspect ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxIdPoliticaDePrivacidade ON dbo.PoliticaDePrivacidadeUsuarioContaSistema (  IdPoliticaDePrivacidade ASC  , IdUsuarioContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdUsuarioContaSistema ON dbo.PoliticaDePrivacidadeUsuarioContaSistema (  IdUsuarioContaSistema ASC  , IdPoliticaDePrivacidade ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idxGUID ON dbo.Produto (  GUID ASC  )  
	 INCLUDE ( Id , IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.Produto (  IdContaSistema ASC  , Status ASC  )  
	 INCLUDE ( Id , Nome ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxNome ON dbo.Produto (  Nome ASC  , IdContaSistema ASC  )  
	 INCLUDE ( Id , Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxVersao ON dbo.Produto (  versao ASC  , Id ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX IDXCAMPANHA ON dbo.ProdutoCampanha (  IdCampanha ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX IDXPRODUTO ON dbo.ProdutoCampanha (  IdProduto ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX IDXPRODUTOCAMPANHA ON dbo.ProdutoCampanha (  IdCampanha ASC  , IdProduto ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

CREATE NONCLUSTERED INDEX IDX1 ON dbo.ProdutoMarco (  IdProdutoMarcoTipo ASC  , DtInicio ASC  , DtFim ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.ProdutoMarco (  idGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.ProdutoMarcoTipo (  idGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX IDXIDPRODUTO ON dbo.ProdutoSub (  IdProduto ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.ProdutoSub (  idGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX IDX1 ON dbo.ProdutoTag (  IdTag ASC  , IdProduto ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX IDXGUID ON dbo.ProdutoTag (  IdGuid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

CREATE NONCLUSTERED INDEX idxContaSistema ON dbo.Prospeccao (  IdContaSistema ASC  , Status ASC  )  
	 INCLUDE ( DtInicioProspeccao , DtUltimoProcessamento , StatusProspeccao ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.Prospeccao (  IdGuid ASC  )  
	 INCLUDE ( Id , IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxStatus ON dbo.Prospeccao (  Status ASC  , StatusProspeccao ASC  , DtInicioProspeccao ASC  )  
	 INCLUDE ( DtUltimoProcessamento , Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxStatusProspeccao ON dbo.Prospeccao (  StatusProspeccao ASC  , Status ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxAtendimento ON dbo.ProspeccaoPessoaProspect (  IdAtendimento ASC  , IdPessoaProspect ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdPessoaProspect ON dbo.ProspeccaoPessoaProspect (  IdPessoaProspect ASC  , IdProspeccao ASC  , IdAtendimento ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdPessoaProspectOrigemPessoaProspect ON dbo.ProspeccaoPessoaProspect (  IdPessoaProspectOrigemPessoaProspect ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdProspeccao ON dbo.ProspeccaoPessoaProspect (  IdProspeccao ASC  , Status ASC  )  
	 INCLUDE ( DtInclusao , DtStatus , IdAtendimento , IdPessoaProspect , IdPessoaProspectOrigemPessoaProspect , StrTag ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX nci_wi_ProspeccaoPessoaProspect_77261E9526D13D4C901762FBEF38AC3B ON dbo.ProspeccaoPessoaProspect (  IdProspeccao ASC  )  
	 INCLUDE ( DtInclusao , DtStatus , IdAtendimento , IdPessoaProspect , IdPessoaProspectOrigemPessoaProspect , Obs , Status , StrTag ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idxIdPessoaProspectOrigem ON dbo.ProspeccaoPessoaProspectOrigem (  IdPessoaProspectOrigem ASC  , IdProspeccao ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdProspeccao ON dbo.ProspeccaoPessoaProspectOrigem (  IdProspeccao ASC  , IdPessoaProspectOrigem ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX IDX1 ON dbo.ProspeccaoTag (  IdProspeccao ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX IDX2 ON dbo.ProspeccaoTag (  IdProspeccao ASC  , StrTag ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

CREATE NONCLUSTERED INDEX idx1 ON dbo.ProspeccaoUsuarioContaSistema (  IdProspeccao ASC  , IdUsuarioContaSistema ASC  )  
	 INCLUDE ( DtUltimoAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2 ON dbo.ProspeccaoUsuarioContaSistema (  IdUsuarioContaSistema ASC  , IdProspeccao ASC  )  
	 INCLUDE ( DtUltimoAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.RegraFidelizacao (  IdContaSistema ASC  )  
	 INCLUDE ( Id , IdGuid ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.RegraFidelizacao (  IdGuid ASC  , IdContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.Relatorio (  idGuid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idxUnique ON dbo.RelatorioContaSistema (  IdRelatorio ASC  , IdContaSistema ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.Remessa (  IdGuid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxTransportadora ON dbo.Remessa (  IdTransportadora ASC  )  
	 INCLUDE ( Id , IdUsuarioContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxUsuarioContaSistema ON dbo.Remessa (  IdUsuarioContaSistema ASC  , IdTransportadora ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.RemessaCustom (  IdGuid ASC  )  
	 INCLUDE ( IdRemessa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxRemessaUnique ON dbo.RemessaCustom (  IdRemessa ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idxCallerIdUnique ON dbo.RemessaDC (  CallerId ASC  )  
	 INCLUDE ( IdRemessa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxDtStatusProcessamento ON dbo.RemessaDC (  DtStatusProcessamento ASC  , StatusProcessamento ASC  )  
	 INCLUDE ( DtStatus , IdRemessa , Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuidUnique ON dbo.RemessaDC (  IdGuid ASC  )  
	 INCLUDE ( IdRemessa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxNumDestino ON dbo.RemessaDC (  NumDestino ASC  , NumOrigem ASC  )  
	 INCLUDE ( IdRemessa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxNumOrigem ON dbo.RemessaDC (  NumOrigem ASC  , NumDestino ASC  )  
	 INCLUDE ( IdRemessa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxStatusProcessamento ON dbo.RemessaDC (  StatusProcessamento ASC  , Status ASC  )  
	 INCLUDE ( DtStatus , DtStatusProcessamento , IdRemessa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.RemessaLog (  IdGuid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxRemessa ON dbo.RemessaLog (  IdRemessa ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idx1 ON dbo.RemessaTotalVoice (  StatusProcessamento ASC  , Status ASC  , DtStatusProcessamento ASC  )  
	 INCLUDE ( DtStatus , IdRemessa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxCallerIdUnique ON dbo.RemessaTotalVoice (  CallerId ASC  )  
	 INCLUDE ( IdRemessa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuidUnique ON dbo.RemessaTotalVoice (  IdGuid ASC  )  
	 INCLUDE ( IdRemessa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxNumDestino ON dbo.RemessaTotalVoice (  DestinoNumero ASC  )  
	 INCLUDE ( IdRemessa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxNumOrigem ON dbo.RemessaTotalVoice (  OrigemNumero ASC  )  
	 INCLUDE ( IdRemessa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.RespostaFichaPesquisa (  IdFichaPesquisa ASC  , IdPergunta ASC  , FichaPesquisaTipo ASC  , IdAtendimento ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idx1 ON dbo.RespostaFichaPesquisa (  IdFichaPesquisa ASC  , IdAtendimento ASC  , FichaPesquisaTipo ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdAtendimento ON dbo.RespostaFichaPesquisa (  IdAtendimento ASC  , IdFichaPesquisa ASC  )  
	 INCLUDE ( FichaPesquisaTipo , Id , IdPergunta ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdPessoaProspect ON dbo.RespostaFichaPesquisa (  IdPessoaProspect ASC  )  
	 INCLUDE ( IdAtendimento , IdPergunta ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idx1 ON dbo.RespostaFichaPesquisaResposta (  IdRespostaFichaPesquisa ASC  , IdResposta ASC  )  
	 INCLUDE ( DtAtualizacaoAuto , Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx2 ON dbo.RespostaFichaPesquisaResposta (  IdResposta ASC  , IdRespostaFichaPesquisa ASC  )  
	 INCLUDE ( DtAtualizacaoAuto , Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idx3 ON dbo.RespostaFichaPesquisaResposta (  DtAtualizacaoAuto ASC  )  
	 INCLUDE ( IdRespostaFichaPesquisa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxCodigoExterno ON dbo.SuperEntidade (  CodigoExterno ASC  , idContaSistema ASC  )  
	 INCLUDE ( Id , StrGuid , SuperEntidadeTipo ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxDtAtualizacaoAuto ON dbo.SuperEntidade (  DtAtualizacaoAuto DESC  , SuperEntidadeTipo ASC  )  
	 INCLUDE ( Id , idContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxDtInclusao ON dbo.SuperEntidade (  DtInclusao ASC  , Id ASC  )  
	 INCLUDE ( idContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxId ON dbo.SuperEntidade (  Id ASC  , DtInclusao ASC  )  
	 INCLUDE ( DtAtualizacaoAuto , idContaSistema , SuperEntidadeTipo ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdContaSistema1 ON dbo.SuperEntidade (  idContaSistema ASC  , SuperEntidadeTipo ASC  , CodigoExterno ASC  )  
	 INCLUDE ( DtInclusao , Id , StrGuid ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxStrGuid ON dbo.SuperEntidade (  StrGuid ASC  )  
	 INCLUDE ( Id , idContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxSuperEntidadeTipo ON dbo.SuperEntidade (  SuperEntidadeTipo ASC  , idContaSistema ASC  , DtAtualizacaoAuto ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idxIdTipoUnique ON dbo.SuperEntidadeAux (  Id ASC  , Tipo ASC  )  
	 INCLUDE ( IdContaSistema , Valor , ValorDt , ValorInt ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxIdSuperEntidade ON dbo.SuperEntidadeLog (  IdSuperEntidade ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

CREATE NONCLUSTERED INDEX idxAtendimentoId ON dbo.TabelaoAlarme (  AtendimentoId ASC  , AlarmeStatus ASC  )  
	 INCLUDE ( AlarmeData , AlarmeId , ContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxContaSistemaId ON dbo.TabelaoAlarme (  ContaSistemaId ASC  , AtendimentoId ASC  )  
	 INCLUDE ( AlarmeData , AlarmeStatus ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxDtAlarme ON dbo.TabelaoAlarme (  AlarmeData ASC  , ContaSistemaId ASC  , AtendimentoId ASC  )  
	 INCLUDE ( AlarmeId , AlarmeStatus ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxAtendimentoDtConclusao ON dbo.TabelaoAtendimento (  AtendimentoDtConclusao DESC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxAtendimentoDtInclusao ON dbo.TabelaoAtendimento (  AtendimentoDtInclusao DESC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxAtendimentoDtInicio ON dbo.TabelaoAtendimento (  AtendimentoDtInicio DESC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxAtendimentoId ON dbo.TabelaoAtendimento (  AtendimentoId ASC  , DtAtualizacaoAuto ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoStatus , CampanhaId , ContaSistemaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxAtendimentoIdMotivacaoNaoConversaoVenda ON dbo.TabelaoAtendimento (  AtendimentoIdMotivacaoNaoConversaoVenda ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxAtendimentoStatus ON dbo.TabelaoAtendimento (  AtendimentoStatus ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxCampanhaId ON dbo.TabelaoAtendimento (  CampanhaId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxCanalId ON dbo.TabelaoAtendimento (  CanalId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxClassificacaoId ON dbo.TabelaoAtendimento (  ClassificacaoId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , ClassificacaoValor2 , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxContaSistemaId ON dbo.TabelaoAtendimento (  ContaSistemaId ASC  , UsuarioContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxGrupoId ON dbo.TabelaoAtendimento (  GrupoId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxMidiaId ON dbo.TabelaoAtendimento (  MidiaId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PecaId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxPessoaProspectId ON dbo.TabelaoAtendimento (  PessoaProspectId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxProdutoId ON dbo.TabelaoAtendimento (  ProdutoId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxProdutoUF ON dbo.TabelaoAtendimento (  ProdutoUF ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxUniqueId ON dbo.TabelaoAtendimento (  AtendimentoId ASC  )  
	 INCLUDE ( ContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxUsuarioContaSistemaId ON dbo.TabelaoAtendimento (  UsuarioContaSistemaId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxAtendimentoDtConclusao ON dbo.TabelaoAtendimentoAux (  AtendimentoDtConclusao DESC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxAtendimentoDtInclusao ON dbo.TabelaoAtendimentoAux (  AtendimentoDtInclusao DESC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxAtendimentoDtInicio ON dbo.TabelaoAtendimentoAux (  AtendimentoDtInicio DESC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxAtendimentoId ON dbo.TabelaoAtendimentoAux (  AtendimentoId ASC  , DtAtualizacaoAuto ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoStatus , CampanhaId , ContaSistemaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxAtendimentoIdMotivacaoNaoConversaoVenda ON dbo.TabelaoAtendimentoAux (  AtendimentoIdMotivacaoNaoConversaoVenda ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxAtendimentoStatus ON dbo.TabelaoAtendimentoAux (  AtendimentoStatus ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxCampanhaId ON dbo.TabelaoAtendimentoAux (  CampanhaId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxCanalId ON dbo.TabelaoAtendimentoAux (  CanalId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxClassificacaoId ON dbo.TabelaoAtendimentoAux (  ClassificacaoId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , ClassificacaoValor2 , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxContaSistemaId ON dbo.TabelaoAtendimentoAux (  ContaSistemaId ASC  , UsuarioContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxGrupoId ON dbo.TabelaoAtendimentoAux (  GrupoId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxMidiaId ON dbo.TabelaoAtendimentoAux (  MidiaId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PecaId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxPessoaProspectId ON dbo.TabelaoAtendimentoAux (  PessoaProspectId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxProdutoId ON dbo.TabelaoAtendimentoAux (  ProdutoId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxProdutoUF ON dbo.TabelaoAtendimentoAux (  ProdutoUF ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId , UsuarioContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxUniqueId ON dbo.TabelaoAtendimentoAux (  AtendimentoId ASC  )  
	 INCLUDE ( ContaSistemaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxUsuarioContaSistemaId ON dbo.TabelaoAtendimentoAux (  UsuarioContaSistemaId ASC  , ContaSistemaId ASC  )  
	 INCLUDE ( AtendimentoDtConclusao , AtendimentoDtInclusao , AtendimentoDtInicio , AtendimentoId , AtendimentoStatus , CampanhaId , GrupoId , PessoaProspectId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.TabelaoFichaPesquisaResposta (  RespostaFichaPesquisaRespostaId ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idx2IdAtendimento ON dbo.TabelaoFichaPesquisaResposta (  IdAtendimento ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , FichaPesquisaId , Id , IdUsuarioContaSistemaRespondido , PerguntaId , RespostaDtRespondido , RespostaFichaPesquisaFichaPesquisaTipo , RespostaFichaPesquisaRespostaId ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxDtInclusao ON dbo.TabelaoInteracaoResumo (  DtInclusao ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxDtInteracao ON dbo.TabelaoInteracaoResumo (  DtInteracao DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxDtInteracaoConclusao ON dbo.TabelaoInteracaoResumo (  DtInteracaoConclusao DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxDtInteracaoInclusao ON dbo.TabelaoInteracaoResumo (  DtInteracaoInclusao DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdAtendimento ON dbo.TabelaoInteracaoResumo (  IdAtendimento ASC  , DtAtualizacaoAuto ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdContaSistema , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdCanal ON dbo.TabelaoInteracaoResumo (  IdCanal DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , IdMidia , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdContaSistema2 ON dbo.TabelaoInteracaoResumo (  IdContaSistema ASC  , IdAtendimento ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoRealizado , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdInteracao ON dbo.TabelaoInteracaoResumo (  IdInteracao ASC  , IdAtendimento ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdContaSistema , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdInteracaoTipo ON dbo.TabelaoInteracaoResumo (  IdInteracaoTipo ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdInteracaoWithVersionIntercao ON dbo.TabelaoInteracaoResumo (  IdInteracao ASC  , versionIntercao ASC  )  
	 INCLUDE ( IdAtendimento , IdContaSistema , versionAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdMidia ON dbo.TabelaoInteracaoResumo (  IdMidia DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdPessoaProspect ON dbo.TabelaoInteracaoResumo (  IdPessoaProspect ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxInteracaoTipoValor ON dbo.TabelaoInteracaoResumo (  InteracaoTipoValor ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxUsuarioContaSistemaIncluiuId ON dbo.TabelaoInteracaoResumo (  UsuarioContaSistemaIncluiuId DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxUsuarioContaSistemaRealizouId ON dbo.TabelaoInteracaoResumo (  UsuarioContaSistemaRealizouId DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxDtInclusao ON dbo.TabelaoInteracaoResumoAux (  DtInclusao ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxDtInteracao ON dbo.TabelaoInteracaoResumoAux (  DtInteracao DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxDtInteracaoConclusao ON dbo.TabelaoInteracaoResumoAux (  DtInteracaoConclusao DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxDtInteracaoInclusao ON dbo.TabelaoInteracaoResumoAux (  DtInteracaoInclusao DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdAtendimento ON dbo.TabelaoInteracaoResumoAux (  IdAtendimento ASC  , DtAtualizacaoAuto ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdContaSistema , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdCanal ON dbo.TabelaoInteracaoResumoAux (  IdCanal DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , IdMidia , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdContaSistema2 ON dbo.TabelaoInteracaoResumoAux (  IdContaSistema ASC  , IdAtendimento ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoRealizado , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdInteracao ON dbo.TabelaoInteracaoResumoAux (  IdInteracao ASC  , IdAtendimento ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdContaSistema , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdInteracaoTipo ON dbo.TabelaoInteracaoResumoAux (  IdInteracaoTipo ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdInteracaoWithVersionIntercao ON dbo.TabelaoInteracaoResumoAux (  IdInteracao ASC  , versionIntercao ASC  )  
	 INCLUDE ( IdAtendimento , IdContaSistema , versionAtendimento ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdMidia ON dbo.TabelaoInteracaoResumoAux (  IdMidia DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdPessoaProspect ON dbo.TabelaoInteracaoResumoAux (  IdPessoaProspect ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxInteracaoTipoValor ON dbo.TabelaoInteracaoResumoAux (  InteracaoTipoValor ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxUsuarioContaSistemaIncluiuId ON dbo.TabelaoInteracaoResumoAux (  UsuarioContaSistemaIncluiuId DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxUsuarioContaSistemaRealizouId ON dbo.TabelaoInteracaoResumoAux (  UsuarioContaSistemaRealizouId DESC  , IdContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracao , DtInteracaoConclusao , DtInteracaoInclusao , IdAtendimento , IdInteracao , IdInteracaoTipo , InteracaoAtorPartida , InteracaoTipoValor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX IDXNOMEUNIQUE ON dbo.TabelaoLog (  Nome ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.Tag (  IdGuid ASC  , IdContaSistema ASC  )  
	 INCLUDE ( Id , Valor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdContaSistema ON dbo.Tag (  IdContaSistema ASC  , Tipo ASC  )  
	 INCLUDE ( DtInclusao , IdGuid , IdUsuarioContaSistema , Valor ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxUnique ON dbo.Tag (  IdContaSistema ASC  , Valor ASC  , Tipo ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxValor ON dbo.Tag (  Valor ASC  , IdContaSistema ASC  , Tipo ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX IDXCODIGOIDCONTASISTEMA ON dbo.TagAtalho (  IdContaSistema ASC  , Codigo ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

CREATE  UNIQUE NONCLUSTERED INDEX idxGuidUnique ON dbo.Telefonia (  IdGuid ASC  )  
	 INCLUDE ( IdTransportadora ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idxGuidUnique ON dbo.TelefoniaDID (  IdGuid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxNumero ON dbo.TelefoniaDID (  Numero ASC  , DDD ASC  )  
	 INCLUDE ( Id , IdTelefoniaTransportadora ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxTelefonia ON dbo.TelefoniaDID (  IdTelefoniaTransportadora ASC  )  
	 INCLUDE ( DDD , Numero ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idxCodigoInterno ON dbo.TemplateIntegracao (  CodigoInterno ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxGuid ON dbo.TemplateIntegracao (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idx1 ON dbo.TemplateIntegracaoIntegradoraExterna (  IdTemplateIntegracao ASC  , IdIntegradoraExterna ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.TemplateIntegracaoIntegradoraExterna (  IdGuid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdIntegradoraExterna ON dbo.TemplateIntegracaoIntegradoraExterna (  IdIntegradoraExterna ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdTemplateIntegracao ON dbo.TemplateIntegracaoIntegradoraExterna (  IdTemplateIntegracao ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idx ON dbo.Teste (  Guid ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX IDX1 ON dbo.Topico (  IdContaSistema ASC  , Status ASC  , Titulo ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX IDX1 ON dbo.TopicoArquivo (  IdTopico ASC  , Status ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.TopicoProduto (  IdTopico ASC  , IdProduto ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX IDXUNIQUE ON dbo.TopicoTag (  IdTag ASC  , IdTopico ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxIdTopico ON dbo.TopicoTag (  IdTopico ASC  )  
	 INCLUDE ( IdTag ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxCodigoExterno ON dbo.Transportadora (  CodigoExterno ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxCodigoExternoIdentificador ON dbo.Transportadora (  CodigoExternoIdentificador ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.Transportadora (  IdGuid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdTransportadoraPai ON dbo.Transportadora (  idTransportadoraPai ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idxIdContaSistemaTransportadoraUnique ON dbo.TransportadoraContaSistema (  IdContaSistema ASC  , IdTransportadora ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuid ON dbo.TransportadoraContaSistema (  IdGuid ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX IDXGUIDUSUARIOCORREX ON dbo.Usuario (  GuidUsuarioCorrex ASC  , IdPessoa ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;

CREATE NONCLUSTERED INDEX idx2DtUltimaRequisicao ON dbo.UsuarioContaSistema (  DtUltimaRequisicao DESC  , Id ASC  )  
	 INCLUDE ( IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxDtExpiracao ON dbo.UsuarioContaSistema (  DtExpiracao ASC  , Status ASC  )  
	 INCLUDE ( Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxGUID ON dbo.UsuarioContaSistema (  GUID ASC  )  
	 INCLUDE ( IdContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdContaSistema ON dbo.UsuarioContaSistema (  IdContaSistema ASC  , IdPessoa ASC  )  
	 INCLUDE ( DtAtualizacao , DtExpiracao , DtInclusao , DtUltimoAcesso , FilaCanalOffLine , FilaCanalOnLine , GUID , Id , idPerfilUsuario , QtdAcesso , Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdContaSistema2 ON dbo.UsuarioContaSistema (  IdContaSistema ASC  , Status ASC  )  
	 INCLUDE ( AccessToken , AccessTokenData , DtAtualizacao , DtExpiracao , DtInclusao , DtUltimoAcesso , FilaCanalOffLine , FilaCanalOnLine , FilaCanalTelefone , GUID , idPerfilUsuario , IdPessoa , QtdAcesso ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdPessoa ON dbo.UsuarioContaSistema (  IdPessoa ASC  , IdContaSistema ASC  )  
	 INCLUDE ( Id , Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdPessoaUnique ON dbo.UsuarioContaSistema (  IdPessoa ASC  , IdContaSistema ASC  )  
	 INCLUDE ( Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdUnique ON dbo.UsuarioContaSistema (  Id ASC  , IdContaSistema ASC  , Status ASC  )  
	 INCLUDE ( GUID , idPerfilUsuario , IdPessoa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxStatus ON dbo.UsuarioContaSistema (  Status ASC  , IdContaSistema ASC  )  
	 INCLUDE ( DtExpiracao , Id , idPerfilUsuario , IdPessoa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxUniqueToken ON dbo.UsuarioContaSistema (  AccessToken ASC  , IdContaSistema ASC  )  
	 INCLUDE ( GUID , Id ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX nci_wi_UsuarioContaSistema_5A721C9CDBE9E6A1BA58F8BCCF1AC52A ON dbo.UsuarioContaSistema (  FilaCanalOnLine ASC  , Status ASC  )  
	 INCLUDE ( DtUltimaRequisicao , FilaCanalOffLine , FilaCanalTelefone , FilaCanalWhatsApp , GUID , IdContaSistema , IdPessoa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX nci_wi_UsuarioContaSistema_DCEDBE0446505C72DE050527DEAECB31 ON dbo.UsuarioContaSistema (  FilaCanalOnLine ASC  , Status ASC  )  
	 INCLUDE ( DtUltimaRequisicao , FilaCanalOffLine , FilaCanalTelefone , GUID , IdContaSistema , IdPessoa ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE  UNIQUE NONCLUSTERED INDEX idxIdCampanhaCanalUnique ON dbo.UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal (  IdCampanhaCanal ASC  , IdPlantaoHorario ASC  , IdUsuarioContaSistema ASC  , IdCampanhaGrupo ASC  )  
	 INCLUDE ( DtInclusao , DtInteracaoFila , Obs , Prioridade ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdUsuarioContaSistema ON dbo.UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal (  IdUsuarioContaSistema ASC  , Status ASC  )  
	 INCLUDE ( Id , IdCampanhaCanal , IdCampanhaGrupo , IdPlantaoHorario ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX nci_wi_UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal_3EB809E1F823B6A07A913DA58C5916A4 ON dbo.UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal (  IdCampanhaGrupo ASC  , IdUsuarioContaSistema ASC  )  
	 INCLUDE ( DtInclusao , DtInteracaoFila , IdCampanhaCanal , IdPlantaoHorario , Obs , Prioridade , Status ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX IDXIDGRUPO ON dbo.UsuarioContaSistemaGrupo (  IdGrupo ASC  , DtFim ASC  )  
	 INCLUDE ( IdUsuarioContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX IDXIDUSUARIOCONTASISTEMA ON dbo.UsuarioContaSistemaGrupo (  IdUsuarioContaSistema ASC  , DtFim ASC  )  
	 INCLUDE ( IdGrupo ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX IDXGRUPO ON dbo.UsuarioContaSistemaGrupoAdm (  IdGrupo ASC  , DtFim ASC  )  
	 INCLUDE ( IdUsuarioContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX IDXIDUSUARIOCONTASISTEMA_ ON dbo.UsuarioContaSistemaGrupoAdm (  IdUsuarioContaSistema ASC  , DtFim ASC  )  
	 INCLUDE ( IdGrupo ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX nci_wi_UsuarioContaSistemaGrupoAdm_292B4E488FC576C4DFA3BE5EF943B18B ON dbo.UsuarioContaSistemaGrupoAdm (  DtFim ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

CREATE NONCLUSTERED INDEX idxDtFim ON dbo.UsuarioContaSistemaPresenca (  DtFim ASC  )  
	 INCLUDE ( IdGuidContaSistema , IdGuidUsuarioContaSistema ) 
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE NONCLUSTERED INDEX idxIdGuidContaSistema ON dbo.UsuarioContaSistemaPresenca (  IdGuidContaSistema ASC  , IdGuidUsuarioContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxIdGuidUsuarioContaSistema ON dbo.UsuarioContaSistemaPresenca (  IdGuidUsuarioContaSistema ASC  , IdGuidContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

CREATE  UNIQUE NONCLUSTERED INDEX idxUniqueIdContaSistema ON dbo.UsuarioContaSistemaPresenca (  IdContaSistema ASC  , IdUsuarioContaSistema ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ];

;

;
