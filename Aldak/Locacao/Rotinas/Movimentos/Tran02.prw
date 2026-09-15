#Include "totvs.ch"
#Include "fwmvcdef.ch"

// Opcao corrente do radio de impressao dos termos (1 = Entrega, 2 = Devolucao).
Static nRadOpc := 1

/*/{Protheus.doc} TRAN02
Transferência em lote de centro de custo / responsável.
Variação da TRAN01: o usuário informa a origem (CC / Responsável) e o destino
(novo CC / novo Responsável) e a rotina transfere todos os documentos ativos.

@author Ewerton Alex Vicentin
@since 10/09/2026
@version P12
/*/
User Function TRAN02()

Local aFields     := {}
Local oTempTable
Private cAliasTmp := GetNextAlias()
// Documentos ativos localizados para o CC / responsavel de origem:
// {ZH_FILIAL, ZH_CODPOST, ZH_LOCALID, ZH_DOC}
Private aDocOri   := {}
// Pares gerados na transferencia em lote (documento original devolvido -> documento novo de entrega):
// {Doc.Origem, Novo Doc.Entrega, Doc.Devolucao, ZH_CODPOST, ZH_LOCALID}
Private aTrmLote  := {}

SZ0->(DbSetOrder(1)) // Cod.Responsável
SZH->(DbSetOrder(2)) // Documento
SZI->(DbSetOrder(5)) // ISSI + Status
SZJ->(DbSetOrder(1)) // Cód.Posto + Localidade + Produto + Patrimônio

AAdd(aFields, {"ZH_CODPOST", "C",   6, 0})
AAdd(aFields, {"ZH_DESCPOS", "C",  40, 0})
AAdd(aFields, {"ZH_LOCALID", "C",   6, 0})
AAdd(aFields, {"ZH_DESCLOC", "C",  40, 0})
AAdd(aFields, {"ZH_CC"     , "C",  30, 0})
AAdd(aFields, {"ZH_DESCCC" , "C", 180, 0})
AAdd(aFields, {"ZH_CODRESP", "C",   6, 0})
AAdd(aFields, {"ZH_RESP"   , "C",  80, 0})
AAdd(aFields, {"ZH_CCNEW"  , "C",  30, 0})
AAdd(aFields, {"ZH_DSCCNEW", "C", 180, 0})
AAdd(aFields, {"ZH_RESPNEW", "C",   6, 0})
AAdd(aFields, {"ZH_NOME"   , "C", 120, 0})

oTempTable := FWTemporaryTable():New(cAliasTmp, aFields)
oTempTable:AddIndex("1", {"ZH_CODPOST", "ZH_LOCALID", "ZH_CC", "ZH_CODRESP"})
oTempTable:Create()

// Registro único em branco: origem e destino são digitados pelo usuário na tela.
RecLock(cAliasTmp, .T.)
(cAliasTmp)->ZH_CODPOST := ""
(cAliasTmp)->ZH_DESCPOS := ""
(cAliasTmp)->ZH_LOCALID := ""
(cAliasTmp)->ZH_DESCLOC := ""
(cAliasTmp)->ZH_CC      := ""
(cAliasTmp)->ZH_DESCCC  := ""
(cAliasTmp)->ZH_CODRESP := ""
(cAliasTmp)->ZH_RESP    := ""
(cAliasTmp)->ZH_CCNEW   := ""
(cAliasTmp)->ZH_DSCCNEW := ""
(cAliasTmp)->ZH_RESPNEW := ""
(cAliasTmp)->ZH_NOME    := ""
MsUnlock()

FWExecView("Transferencia em Lote", "TRAN02", MODEL_OPERATION_INSERT, , { || .T. })

If Select(cAliasTmp) > 0
    (cAliasTmp)->(DbCloseArea())
EndIf

// Impressao dos termos dos documentos gerados no lote. O usuario pode sair sem
// imprimir: a gravacao ja foi confirmada e nao e desfeita.
If !Empty(aTrmLote)
    DlgTermos(aTrmLote)
EndIf

If oTempTable <> Nil
    oTempTable:Delete()
EndIf

Return

/*/{Protheus.doc} MODELDEF
Modelo de Dados do MVC.

@author Ewerton Alex Vicentin
@since 10/09/2026
@version P12
/*/
Static Function ModelDef()

Local oModel
Local oStruTMP := FWFormModelStruct():New()

oStruTMP:AddTable(cAliasTmp, {"ZH_CODPOST", "ZH_LOCALID", "ZH_CC", "ZH_CODRESP"}, "SZHTEMP")

// [01]  C   Titulo do campo
// [02]  C   ToolTip do campo
// [03]  C   Id do Field
// [04]  C   Tipo do campo
// [05]  N   Tamanho do campo
// [06]  N   Decimal do campo
// [07]  B   Code-block de validação do campo
// [08]  B   Code-block de validação When do campo
// [09]  A   Lista de valores permitido do campo
// [10]  L   Indica se o campo tem preenchimento obrigatório
// [11]  B   Code-block de inicializacao do campo
// [12]  L   Indica se trata-se de um campo chave
// [13]  L   Indica se o campo pode receber valor em uma operação de update.
// [14]  L   Indica se o campo é virtual

oStruTMP:AddField("Cod.Posto"  , "Cod.Posto"  , "ZH_CODPOST", "C",   6, 0, {|| VldPost()}  , {|| .T.}, {}, .T., Nil, .F., .T., .F.)
oStruTMP:AddField("Desc.Posto" , "Desc.Posto" , "ZH_DESCPOS", "C",  40, 0, Nil             , {|| .T.}, {}, .F., Nil, .F., .T., .F.)
oStruTMP:AddField("Localidade" , "Localidade" , "ZH_LOCALID", "C",   6, 0, {|| VldLocal()} , {|| .T.}, {}, .T., Nil, .F., .T., .F.)
oStruTMP:AddField("Desc.Local" , "Desc.Local" , "ZH_DESCLOC", "C",  40, 0, Nil             , {|| .T.}, {}, .F., Nil, .F., .T., .F.)
oStruTMP:AddField("CC Origem"  , "CC Origem"  , "ZH_CC"     , "C",  30, 0, {|| VldCCOri()} , {|| .T.}, {}, .T., Nil, .F., .T., .F.)
oStruTMP:AddField("Desc.CC"    , "Desc.CC"    , "ZH_DESCCC" , "C", 180, 0, Nil             , {|| .T.}, {}, .F., Nil, .F., .T., .F.)
oStruTMP:AddField("Cod.Resp."  , "Cod.Resp."  , "ZH_CODRESP", "C",   6, 0, {|| VldRspOri()}, {|| .T.}, {}, .T., Nil, .F., .T., .F.)
oStruTMP:AddField("Responsavel", "Responsavel", "ZH_RESP"   , "C",  80, 0, Nil             , {|| .T.}, {}, .F., Nil, .F., .T., .F.)
oStruTMP:AddField("Novo CC"    , "Novo CC"    , "ZH_CCNEW"  , "C",  30, 0, {|| VldCCNew()} , {|| .T.}, {}, .T., Nil, .F., .T., .F.)
oStruTMP:AddField("Desc.CC"    , "Desc.CC"    , "ZH_DSCCNEW", "C", 180, 0, Nil             , {|| .T.}, {}, .F., Nil, .F., .T., .F.)
oStruTMP:AddField("Novo Resp." , "Novo Resp." , "ZH_RESPNEW", "C",   6, 0, {|| VldRspNew()}, {|| .T.}, {}, .T., Nil, .F., .T., .F.)
oStruTMP:AddField("Nome Resp." , "Nome Resp." , "ZH_NOME"   , "C", 120, 0, Nil             , {|| .T.}, {}, .F., Nil, .F., .T., .F.)

oModel := MPFormModel():New("TRAN02M", /*bPreValidacao*/, {|oMdl| VldTran(oMdl)}, {|oMdl| AtuaLote(oMdl)}, /*bCancel*/)
oModel:AddFields("SZHTMP", /*cOwner*/, oStruTMP)

oModel:SetPrimaryKey({})

oModel:SetDescription("Transferencia em Lote")
oModel:GetModel("SZHTMP"):SetDescription("Origem e Destino")

Return(oModel)

/*/{Protheus.doc} VIEWDEF
View do MVC.

@author Ewerton Alex Vicentin
@since 10/09/2026
@version P12
/*/
Static Function ViewDef()

Local oView
Local oStruTMP := FWFormViewStruct():New()
Local oModel   := FWLoadModel("TRAN02")

// [01]  C   Nome do Campo
// [02]  C   Ordem
// [03]  C   Titulo do campo
// [04]  C   Descricao do campo
// [05]  A   Array com Help
// [06]  C   Tipo do campo
// [07]  C   Picture
// [08]  B   Bloco de Picture Var
// [09]  C   Consulta F3
// [10]  L   Indica se o campo é alteravel
// [11]  C   Pasta do campo
// [12]  C   Agrupamento do campo
// [13]  A   Lista de valores permitido do campo (Combo)
// [14]  N   Tamanho maximo da maior opção do combo
// [15]  C   Inicializador de Browse
// [16]  L   Indica se o campo é virtual
// [17]  C   Picture Variavel
// [18]  L   Indica pulo de linha após o campo

oStruTMP:AddField("ZH_CODPOST", "01", "Cod.Posto"  , "Cod.Posto"  , Nil, "C", "@!", Nil, "SZ1", .T., Nil, Nil, Nil, Nil, Nil, Nil, Nil, Nil)
oStruTMP:AddField("ZH_DESCPOS", "02", "Desc.Posto" , "Desc.Posto" , Nil, "C", "@!", Nil, Nil  , .F., Nil, Nil, Nil, Nil, Nil, Nil, Nil, .T.)
oStruTMP:AddField("ZH_LOCALID", "03", "Localidade" , "Localidade" , Nil, "C", "@!", Nil, "SZ2", .T., Nil, Nil, Nil, Nil, Nil, Nil, Nil, Nil)
oStruTMP:AddField("ZH_DESCLOC", "04", "Desc.Local" , "Desc.Local" , Nil, "C", "@!", Nil, Nil  , .F., Nil, Nil, Nil, Nil, Nil, Nil, Nil, .T.)
oStruTMP:AddField("ZH_CC"     , "05", "CC Origem"  , "CC Origem"  , Nil, "C", "@!", Nil, "SZ5", .T., Nil, Nil, Nil, Nil, Nil, Nil, Nil, Nil)
oStruTMP:AddField("ZH_DESCCC" , "06", "Desc.CC"    , "Desc.CC"    , Nil, "C", "@!", Nil, Nil  , .F., Nil, Nil, Nil, Nil, Nil, Nil, Nil, .T.)
oStruTMP:AddField("ZH_CODRESP", "07", "Resp.Orig." , "Resp.Orig." , Nil, "C", "@!", Nil, "SZ0", .T., Nil, Nil, Nil, Nil, Nil, Nil, Nil, Nil)
oStruTMP:AddField("ZH_RESP"   , "08", "Responsavel", "Responsavel", Nil, "C", "@!", Nil, Nil  , .F., Nil, Nil, Nil, Nil, Nil, Nil, Nil, .T.)
oStruTMP:AddField("ZH_CCNEW"  , "09", "Novo CC"    , "Novo CC"    , Nil, "C", "@!", Nil, "SZ5", .T., Nil, Nil, Nil, Nil, Nil, Nil, Nil, Nil)
oStruTMP:AddField("ZH_DSCCNEW", "10", "Desc.CC"    , "Desc.CC"    , Nil, "C", "@!", Nil, Nil  , .F., Nil, Nil, Nil, Nil, Nil, Nil, Nil, .T.)
oStruTMP:AddField("ZH_RESPNEW", "11", "Novo Resp." , "Novo Resp." , Nil, "C", "@!", Nil, "SZ0", .T., Nil, Nil, Nil, Nil, Nil, Nil, Nil, Nil)
oStruTMP:AddField("ZH_NOME"   , "12", "Nome"       , "Nome"       , Nil, "C", "@!", Nil, Nil  , .F., Nil, Nil, Nil, Nil, Nil, Nil, Nil, Nil)

oView := FWFormView():New()

oView:SetModel(oModel)

oView:AddField("VIEWSZH", oStruTMP, "SZHTMP")

oView:SetCloseOnOk({|| .T.})

oView:CreateHorizontalBox("CABEC", 100)

oView:SetOwnerView("VIEWSZH", "CABEC")

Return(oView)

/*/{Protheus.doc} VldPost
Validacao do Cod.Posto: critica a existencia no SZ1 e carrega a descricao.

@return lRet .T. se o posto informado e valido

@author Ewerton Alex Vicentin
@since 10/09/2026
@version P12
/*/
Static Function VldPost()

Local oModel    := FWModelActive()
Local oModelSZH := oModel:GetModel("SZHTMP")
Local cPosto    := oModelSZH:GetValue("ZH_CODPOST")
Local cLocal    := oModelSZH:GetValue("ZH_LOCALID")

SZ1->(DbSetOrder(1))
SZ2->(DbSetOrder(1))

If !Empty(cPosto)
    If !SZ1->(DbSeek(xFilial("SZ1") + cPosto))
        Return .F.
    EndIf
EndIf

oModelSZH:LoadValue("ZH_DESCPOS", Posicione("SZ1", 1, xFilial("SZ1") + cPosto, "Z1_DESCRI"))

// A localidade depende do posto: ao trocar o posto a localidade anterior deixa de
// valer e e limpa junto com a descricao.
If !Empty(cLocal)
    If Empty(cPosto) .Or. !SZ2->(DbSeek(xFilial("SZ2") + cPosto + cLocal))
        oModelSZH:LoadValue("ZH_LOCALID", "")
        oModelSZH:LoadValue("ZH_DESCLOC", "")
    EndIf
EndIf

Return .T.

/*/{Protheus.doc} VldLocal
Validacao da Localidade: exige o Cod.Posto informado, critica a existencia no
SZ2 (posto + localidade) e carrega a descricao.

@return lRet .T. se a localidade informada e valida

@author Ewerton Alex Vicentin
@since 10/09/2026
@version P12
/*/
Static Function VldLocal()

Local oModel    := FWModelActive()
Local oModelSZH := oModel:GetModel("SZHTMP")
Local cPosto    := AllTrim(oModelSZH:GetValue("ZH_CODPOST"))
Local cLocal    := AllTrim(oModelSZH:GetValue("ZH_LOCALID"))

SZ2->(DbSetOrder(1))

If !Empty(cLocal)
    If Empty(cPosto)
        Help(, , "TRAN02", , "Informe primeiro o Cod.Posto.", 1, 0)
        Return .F.
    EndIf

    If !SZ2->(DbSeek(xFilial("SZ2") + cPosto + cLocal))
        Return .F.
    EndIf
EndIf

oModelSZH:LoadValue("ZH_DESCLOC", Posicione("SZ2", 1, xFilial("SZ2") + cPosto + cLocal, "Z2_DESCRI"))

Return .T.

/*/{Protheus.doc} VldCCOri
Validacao do CC de origem: carrega a descricao do CC e, quando o responsavel de
origem ja estiver informado, confere se existem documentos ativos.

@param oModel Modelo do MVC
@return lRet .T. se o CC de origem e valido

@author Ewerton Alex Vicentin
@since 10/09/2026
@version P12
/*/
Static Function VldCCOri()

Local lRet      := .T.
Local oModel    := FWModelActive()
Local oModelSZH := oModel:GetModel("SZHTMP")
Local cPosto    := oModelSZH:GetValue("ZH_CODPOST")
Local cCCOri    := oModelSZH:GetValue("ZH_CC")
Local cRespOri  :=oModelSZH:GetValue("ZH_CODRESP")

SZ5->(DbSetOrder(1)) // Cod.posto + Cód. C.C.

If !Empty(cCCOri)
    If !SZ5->(DbSeek(xFilial("SZ5") + cPosto + cCCOri))
        Return .F.
    EndIf
EndIf

oModelSZH:LoadValue("ZH_DESCCC", Posicione("SZ5", 1, xFilial("SZ5") + cPosto + cCCOri, "Z5_DESCRI"))

If !Empty(cRespOri)
    lRet := ChkOrigem(oModelSZH, cCCOri, cRespOri)
EndIf

Return lRet

/*/{Protheus.doc} VldRspOri
Validacao do responsavel de origem: carrega o nome e confere os documentos ativos.

@param oModel Modelo do MVC
@return lRet .T. se o responsavel de origem e valido

@author Ewerton Alex Vicentin
@since 10/09/2026
@version P12
/*/
Static Function VldRspOri()

Local lRet      := .T.
Local oModel    := FWModelActive()
Local oModelSZH := oModel:GetModel("SZHTMP")
Local cPosto    := oModelSZH:GetValue("ZH_CODPOST")
Local cCCOri    := oModelSZH:GetValue("ZH_CC")
Local cRespOri  := oModelSZH:GetValue("ZH_CODRESP")

SZ0->(DbSetOrder(1)) // Cod.posto + Cód. responsável

If !Empty(cRespOri)
    If !SZ0->(DbSeek(xFilial("SZ0") + cPosto + cRespOri))
        Return .F.
    EndIf
EndIf

oModelSZH:LoadValue("ZH_RESP", Posicione("SZ0", 1, xFilial("SZ0") + cPosto + cRespOri, "Z0_NOME"))

If !Empty(cCCOri)
    lRet := ChkOrigem(oModelSZH, cCCOri, cRespOri)
EndIf

Return lRet

/*/{Protheus.doc} VldCCNew
Validacao do novo CC: carrega a descricao e impede origem igual ao destino.

@param oModel Modelo do MVC
@return lRet .T. se o novo CC e valido

@author Ewerton Alex Vicentin
@since 10/09/2026
@version P12
/*/
Static  Function VldCCNew()

Local oModel    := FWModelActive()
Local oModelSZH := oModel:GetModel("SZHTMP")
Local cPosto    := AllTrim(oModelSZH:GetValue("ZH_CODPOST"))
Local cCCOri    := AllTrim(oModelSZH:GetValue("ZH_CC"))
Local cCCNew    := AllTrim(oModelSZH:GetValue("ZH_CCNEW"))

SZ5->(DbSetOrder(1)) // Cod.posto + Cód. C.C.

If !Empty(cCCNew)
    If !SZ5->(DbSeek(xFilial("SZ5") + cPosto + cCCNew))
        Return .F.
    EndIf
EndIf

If !Empty(cCCOri) .And. cCCOri == cCCNew
    Help(, , "TRAN02", , "O novo CC deve ser diferente do CC de origem.", 1, 0)
    Return .F.
EndIf

oModelSZH:LoadValue("ZH_DSCCNEW", Posicione("SZ5", 1, xFilial("SZ5") + cCCNew, "Z5_DESCRI"))

Return .T.

/*/{Protheus.doc} VldRspNew
Validacao do novo responsavel: carrega o nome e impede origem igual ao destino.

@param oModel Modelo do MVC
@return lRet .T. se o novo responsavel e valido

@author Ewerton Alex Vicentin
@since 10/09/2026
@version P12
/*/
Static Function VldRspNew()

Local oModel    := FWModelActive()
Local oModelSZH := oModel:GetModel("SZHTMP")
Local cPosto    := oModelSZH:GetValue("ZH_CODPOST")
Local cRespOri  := oModelSZH:GetValue("ZH_CODRESP")
Local cRespNew  := oModelSZH:GetValue("ZH_RESPNEW")

SZ0->(DbSetOrder(1)) // Cod.posto + Cód. responsável

If !Empty(cRespNew)
    If !SZ0->(DbSeek(xFilial("SZ0") + cPosto + cRespNew))
        Return .F.
    EndIf
EndIf

If !Empty(cRespOri) .And. cRespOri == cRespNew
    Help(, , "TRAN02", , "O novo responsavel deve ser diferente do responsavel de origem.", 1, 0)
    Return .F.
EndIf

oModelSZH:LoadValue("ZH_NOME", Posicione("SZ0", 1, xFilial("SZ0") + cPosto + cRespNew, "Z0_NOME"))

Return .T.

/*/{Protheus.doc} ChkOrigem
Localiza os documentos ativos da origem e critica quando nao houver nenhum.
Quando o posto e/ou a localidade estiverem informados na tela, a busca fica
restrita a eles.

@param oModelSZH Submodelo de campos
@param cCCOri    CC de origem
@param cRespOri  Responsavel de origem
@param cPosto    Cod.Posto (opcional, quando nao informado le do submodelo)
@param cLocal    Localidade (opcional, quando nao informada le do submodelo)
@return lRet .T. quando existem documentos ativos

@author Ewerton Alex Vicentin
@since 10/09/2026
@version P12
/*/
Static Function ChkOrigem(oModelSZH, cCCOri, cRespOri, cPosto, cLocal)

Local cMsg := ""

Default cCCOri   := ""
Default cRespOri := ""
Default cPosto   := AllTrim(oModelSZH:GetValue("ZH_CODPOST"))
Default cLocal   := AllTrim(oModelSZH:GetValue("ZH_LOCALID"))

aDocOri := ChkDocs(cCCOri, cRespOri, cPosto, cLocal)

If Empty(aDocOri)
    cMsg := "Não existem documentos ativos para o CC e responsavel informados"

    If !Empty(cPosto)
        cMsg += " no posto [" + AllTrim(cPosto) + "]"
    EndIf

    If !Empty(cLocal)
        cMsg += " / localidade [" + AllTrim(cLocal) + "]"
    EndIf

    Help(, , "TRAN02", , cMsg + ".", 1, 0)
    Return .F.
EndIf

Return .T.

/*/{Protheus.doc} VldTran
Pos-validacao do modelo: exige os quatro campos, impede origem igual ao destino
e confere se existem documentos ativos para a origem informada.

@param oModel Modelo do MVC
@return lRet .T. quando a transferencia pode ser confirmada

@author Ewerton Alex Vicentin
@since 10/09/2026
@version P12
/*/
Static Function VldTran(oModel)

Local oModelSZH := oModel:GetModel("SZHTMP")
Local cPosto    := AllTrim(oModelSZH:GetValue("ZH_CODPOST"))
Local cLocal    := AllTrim(oModelSZH:GetValue("ZH_LOCALID"))
Local cCCOri    := AllTrim(oModelSZH:GetValue("ZH_CC"))
Local cRespOri  := AllTrim(oModelSZH:GetValue("ZH_CODRESP"))
Local cCCNew    := AllTrim(oModelSZH:GetValue("ZH_CCNEW"))
Local cRespNew  := AllTrim(oModelSZH:GetValue("ZH_RESPNEW"))

If Empty(cPosto) .Or. Empty(cLocal)
    Help(, , "TRAN02", , "Informe o Cod.Posto e a Localidade.", 1, 0)
    Return .F.
EndIf

If Empty(cCCOri) .Or. Empty(cRespOri) .Or. Empty(cCCNew) .Or. Empty(cRespNew)
    Help(, , "TRAN02", , "Informe o CC e o responsavel de origem e de destino.", 1, 0)
    Return .F.
EndIf

If cCCOri == cCCNew .And. cRespOri == cRespNew
    Help(, , "TRAN02", , "A origem e o destino informados sao iguais.", 1, 0)
    Return .F.
EndIf

Return ChkOrigem(oModelSZH, cCCOri, cRespOri, cPosto, cLocal)

/*/{Protheus.doc} ChkDocs
Localiza os documentos (SZH) com itens ativos (SZI) para o CC e o responsavel
de origem informados. O posto e a localidade sao filtros opcionais: quando
informados, restringem os documentos retornados.

@param cCCOri   CC de origem
@param cRespOri Responsavel de origem
@param cPosto   Cod.Posto (opcional)
@param cLocal   Localidade (opcional)
@return aRet Array {ZH_FILIAL, ZH_CODPOST, ZH_LOCALID, ZH_DOC}

@author Ewerton Alex Vicentin
@since 10/09/2026
@version P12
/*/
Static Function ChkDocs(cCCOri, cRespOri, cPosto, cLocal)

Local aRet     := {}
Local cAliasQr := GetNextAlias()
// Flags de filtro: 0 = campo nao informado (clausula nao restringe a consulta).
Local nFltPost := 0
Local nFltLoc  := 0

Default cCCOri   := ""
Default cRespOri := ""
Default cPosto   := ""
Default cLocal   := ""

If !Empty(cPosto)
    nFltPost := 1
EndIf

If !Empty(cLocal)
    nFltLoc := 1
EndIf

BeginSql Alias cAliasQr
    SELECT
        SZH.ZH_FILIAL, SZH.ZH_CODPOST, SZH.ZH_LOCALID, SZH.ZH_DOC
    FROM
        %Table:SZH% SZH
    WHERE
        SZH.ZH_FILIAL = %xFilial:SZH% AND
        SZH.ZH_CC = %Exp:cCCOri% AND
        SZH.ZH_CODRESP = %Exp:cRespOri% AND
        (%Exp:nFltPost% = 0 OR SZH.ZH_CODPOST = %Exp:cPosto%) AND
        (%Exp:nFltLoc% = 0 OR SZH.ZH_LOCALID = %Exp:cLocal%) AND
        SZH.%NotDel% AND
        EXISTS (SELECT 1
                  FROM %Table:SZI% SZI
                 WHERE SZI.ZI_FILIAL = %xFilial:SZI% AND
                       SZI.ZI_CODPOST = SZH.ZH_CODPOST AND
                       SZI.ZI_LOCALID = SZH.ZH_LOCALID AND
                       SZI.ZI_DOC = SZH.ZH_DOC AND
                       SZI.ZI_STATUS = 'A' AND
                       SZI.%NotDel%)
    ORDER BY SZH.ZH_CODPOST, SZH.ZH_LOCALID, SZH.ZH_DOC
EndSql

While !(cAliasQr)->(EOF())
    AAdd(aRet, {(cAliasQr)->ZH_FILIAL ,;
                (cAliasQr)->ZH_CODPOST,;
                (cAliasQr)->ZH_LOCALID,;
                (cAliasQr)->ZH_DOC     })
    (cAliasQr)->(DbSkip())
End

(cAliasQr)->(DbCloseArea())

Return aRet

/*/{Protheus.doc} AtuaLote
Grava a transferencia em lote: percorre os documentos ativos da origem e, para
cada um, reproduz a gravacao da TRAN01 (documento de devolucao + novo documento
de entrega com o novo CC / responsavel).

@param oModel Modelo do MVC
@return lRet .T. quando todos os documentos foram transferidos

@author Ewerton Alex Vicentin
@since 10/09/2026
@version P12
/*/
Static Function AtuaLote(oModel)

Local lRet       := .T.
Local nX         := 0
Local nOperation := oModel:GetOperation()
Local oModelSZH  := oModel:GetModel("SZHTMP")
Local cPosto     := AllTrim(oModelSZH:GetValue("ZH_CODPOST"))
Local cLocal     := AllTrim(oModelSZH:GetValue("ZH_LOCALID"))
Local cCCOri     := AllTrim(oModelSZH:GetValue("ZH_CC"))
Local cRespOri   := AllTrim(oModelSZH:GetValue("ZH_CODRESP"))
Local cCCNew     := oModelSZH:GetValue("ZH_CCNEW")
Local cRespNew   := oModelSZH:GetValue("ZH_RESPNEW")
Local aDocs      := {}
Local aGerados   := {}
Local aDocNew    := {}
Local cMsg       := ""

If nOperation <> MODEL_OPERATION_INSERT
    Return .T.
EndIf

// aDocs[n] - {ZH_FILIAL, ZH_CODPOST, ZH_LOCALID, ZH_DOC}
aDocs := ChkDocs(cCCOri, cRespOri, cPosto, cLocal)

If Empty(aDocs)
    Help(, , "TRAN02", , "Nao existem documentos ativos para o CC e responsavel informados.", 1, 0)
    Return .F.
EndIf

Begin Transaction

    For nX := 1 To Len(aDocs)
        // aDocNew - {cNewDoc (entrega), cNewDev (devolucao)}
        aDocNew := AtuaDoc(aDocs[nX, 1], aDocs[nX, 2], aDocs[nX, 3], aDocs[nX, 4], cCCNew, cRespNew)

        If Empty(aDocNew)
            lRet := .F.
            DisarmTransaction()
            Help(, , "TRAN02", , "Falha na transferencia do documento [" + AllTrim(aDocs[nX, 4]) + "]. Nenhum documento foi gravado.", 1, 0)
            Exit
        EndIf

        // {Doc.Origem, Novo Doc.Entrega, Doc.Devolucao, Cod.Posto, Localidade}
        AAdd(aGerados, {aDocs[nX, 4], aDocNew[1], aDocNew[2], aDocs[nX, 2], aDocs[nX, 3]})
    Next nX

End Transaction

If !lRet
    Return .F.
EndIf

cMsg := "Transferencia concluida. Total de documentos transferidos: " + AllTrim(Str(Len(aGerados))) + CRLF + CRLF

For nX := 1 To Len(aGerados)
    cMsg += AllTrim(aGerados[nX, 1]) + " -> Entrega [" + AllTrim(aGerados[nX, 2]) + "] - Devolucao [" + AllTrim(aGerados[nX, 3]) + "]" + CRLF
Next nX

aDocOri := aGerados

// Lista de pares (documento original devolvido -> documento novo de entrega)
// usada na impressao dos termos apos o commit.
aTrmLote := aGerados

MsgInfo(cMsg, "Atencao")

Return lRet

/*/{Protheus.doc} AtuaDoc
Reproduz, para um unico documento, o fluxo de gravacao da TRAN01 (AtuaTransf):
gera o documento de devolucao do original, baixa os itens ativos do documento de
origem e gera o novo documento de entrega com o novo CC / responsavel.

@param cFilOri  Filial do documento de origem
@param cPostOri Cod.Posto do documento de origem
@param cLocOri  Localidade do documento de origem
@param cDocOri  Documento de origem
@param cCCNew   Novo CC
@param cRespNew Novo responsavel
@return aRet {Novo documento de entrega, documento de devolucao} ou {} em caso de falha

@author Ewerton Alex Vicentin
@since 10/09/2026
@version P12
/*/
Static Function AtuaDoc(cFilOri, cPostOri, cLocOri, cDocOri, cCCNew, cRespNew)

Local aRet       := {}
Local aItDoc     := {}
Local nX         := 0
Local cCCusto    := ""
Local cResp      := ""
Local cChamado   := ""
Local cMotivo    := ""
Local cNewDoc    := ""
Local cNewDev    := ""
Local cDoc       := ""
Local cItem      := ""
Local cProduto   := ""
Local cPatrim    := ""
Local cNumSer    := ""
Local cISSIIt    := ""
Local cKit       := ""
Local nQuant     := 0
Local cLocaliz   := ""
Local cDescri    := ""
Local cNumSeq    := ""
Local dDtBaseDev := Ctod("15/" + StrZero(Month(dDataBase),2) + "/" + AllTrim(Str(Year(dDataBase))))
Local dDtBaseEnt := Ctod("16/" + StrZero(Month(dDataBase),2) + "/" + AllTrim(Str(Year(dDataBase))))

Default cFilOri  := ""
Default cPostOri := ""
Default cLocOri  := ""
Default cDocOri  := ""
Default cCCNew   := ""
Default cRespNew := ""

SB1->(DbSetOrder(1)) // Codigo
SZH->(DbSetOrder(2)) // Documento
SZI->(DbSetOrder(5)) // ISSI + Documento + Item
SZJ->(DbSetOrder(1)) // Cod.Posto + Localidade + Produto + Patrimonio
SZK->(DbSetOrder(1)) // Cliente + Loja + Patrimonio

If !SZH->(DbSeek(xFilial("SZH") + cDocOri))
    Return {}
EndIf

cCCusto  := SZH->ZH_CC
cResp    := SZH->ZH_CODRESP
cChamado := SZH->ZH_CHAMADO
cMotivo  := SZH->ZH_MOTIVO

// aItDoc
// [1] - ZI_DOC     [2] - ZI_ITEM    [3] - ZI_PRODUTO [4] - ZI_PATRIM
// [5] - ZI_NUMSER  [6] - ZI_ISSI    [7] - ZI_CODKIT  [8] - ZI_QUANT
// [9] - ZI_LOCALIZ [10] - ZI_DATAMOV [11] - ZI_DESCRI [12] - ZI_NUMSEQ
aItDoc := RetItDoc(cPostOri, cLocOri, cDocOri)

If Empty(aItDoc)
    Return {}
EndIf

// Grava o documento de devolucao.
cNewDev := GetSXENum("SZH", "ZH_DOC")

RecLock("SZH", .T.)
SZH->ZH_FILIAL  := xFilial("SZH")
SZH->ZH_DOC     := cNewDev
SZH->ZH_EMISSAO := dDataBase
SZH->ZH_CODPOST := cPostOri
SZH->ZH_LOCALID := cLocOri
SZH->ZH_CC      := cCCusto
SZH->ZH_CODRESP := cResp
SZH->ZH_CHAMADO := cChamado
SZH->ZH_MOTIVO  := cMotivo
SZH->ZH_STATUS  := "D"
MsUnlock()

For nX := 1 To Len(aItDoc)
    cItem     := aItDoc[nX, 2]
    cProduto  := aItDoc[nX, 3]
    cPatrim   := aItDoc[nX, 4]
    cNumSer   := aItDoc[nX, 5]
    cISSIIt   := aItDoc[nX, 6]
    cKit      := aItDoc[nX, 7]
    nQuant    := aItDoc[nX, 8]
    cLocaliz  := aItDoc[nX, 9]
    cDescri   := aItDoc[nX, 11]
    cNumSeq   := aItDoc[nX, 12]

    // Grava o item devolvido.
    RecLock("SZI", .T.)
    SZI->ZI_FILIAL  := xFilial("SZI")
    SZI->ZI_CODPOST := cPostOri
    SZI->ZI_LOCALID := cLocOri
    SZI->ZI_DOC     := cNewDev
    SZI->ZI_STATUS  := "V" // Devolvido, sem efeito de medicao, apenas para gerar o documento de devolucao.
    SZI->ZI_ITEM    := cItem
    SZI->ZI_PRODUTO := cProduto
    SZI->ZI_PATRIM  := cPatrim
    SZI->ZI_NUMSER  := cNumSer
    SZI->ZI_ISSI    := cISSIIt
    SZI->ZI_CODKIT  := cKit
    SZI->ZI_QUANT   := nQuant
    SZI->ZI_LOCALIZ := cLocaliz
    SZI->ZI_DATAMOV := dDataBase
    SZI->ZI_DESCRI  := cDescri
    SZI->ZI_NUMSEQ  := cNumSeq
    SZI->ZI_DTBASE  := dDtBaseDev
    MsUnlock()
Next nX

// Commit no cNewDev.
ConfirmSX8()

// Baixa os itens que estao sendo devolvidos no documento original de entrega.
cNewDoc := GetSXENum("SZH", "ZH_DOC")

For nX := 1 To Len(aItDoc)
    cDoc      := aItDoc[nX, 1]
    cItem     := aItDoc[nX, 2]
    cProduto  := aItDoc[nX, 3]
    cPatrim   := aItDoc[nX, 4]
    cISSIIt   := aItDoc[nX, 6]
    cNumSer   := aItDoc[nX, 5]
    nQuant    := aItDoc[nX, 8]

    If SZI->(DbSeek(xFilial("SZI") + cISSIIt + cDoc + cItem))
        // Atualiza o status para devolvido.
        RecLock("SZI", .F.)
        SZI->ZI_STATUS  := "V" // Devolvido, sem efeito, nao entra na medicao.
        SZI->ZI_DATADEV := CtoD("01/01/1990")
        SZI->ZI_PERDA   := 0
        SZI->ZI_DOCSUBS := cNewDev
        MsUnlock()
    EndIf
Next nX

// Grava o novo documento de transferencia (Entrega).
RecLock("SZH", .T.)
SZH->ZH_FILIAL  := xFilial("SZH")
SZH->ZH_DOC     := cNewDoc
SZH->ZH_EMISSAO := dDataBase
SZH->ZH_CODPOST := cPostOri
SZH->ZH_LOCALID := cLocOri
SZH->ZH_CC      := cCCNew
SZH->ZH_CODRESP := cRespNew
SZH->ZH_CHAMADO := cChamado
SZH->ZH_MOTIVO  := cMotivo
SZH->ZH_STATUS  := "A"
MsUnlock()

For nX := 1 To Len(aItDoc)
    cItem     := aItDoc[nX, 2]
    cProduto  := aItDoc[nX, 3]
    cPatrim   := aItDoc[nX, 4]
    cNumSer   := aItDoc[nX, 5]
    cISSIIt   := aItDoc[nX, 6]
    cKit      := aItDoc[nX, 7]
    nQuant    := aItDoc[nX, 8]
    cLocaliz  := aItDoc[nX, 9]
    cDescri   := aItDoc[nX, 11]
    cNumSeq   := aItDoc[nX, 12]

    // Grava o item novo.
    RecLock("SZI", .T.)
    SZI->ZI_FILIAL  := xFilial("SZI")
    SZI->ZI_CODPOST := cPostOri
    SZI->ZI_LOCALID := cLocOri
    SZI->ZI_DOC     := cNewDoc
    SZI->ZI_STATUS  := "A"
    SZI->ZI_ITEM    := cItem
    SZI->ZI_PRODUTO := cProduto
    SZI->ZI_PATRIM  := cPatrim
    SZI->ZI_NUMSER  := cNumSer
    SZI->ZI_ISSI    := cISSIIt
    SZI->ZI_CODKIT  := cKit
    SZI->ZI_QUANT   := nQuant
    SZI->ZI_LOCALIZ := cLocaliz
    SZI->ZI_DATAMOV := dDataBase
    SZI->ZI_DESCRI  := cDescri
    SZI->ZI_NUMSEQ  := cNumSeq
    SZI->ZI_DTBASE  := dDtBaseEnt
    MsUnlock()
Next nX

// Commit no cNewDoc.
ConfirmSX8()

aRet := {cNewDoc, cNewDev}

Return aRet

/*/{Protheus.doc} RetItDoc
Retorna os itens ativos (ZI_STATUS = 'A') de um documento de entrega.

@param cPostOri Cod.Posto do documento
@param cLocOri  Localidade do documento
@param cDocOri  Documento
@return aRet Array com os itens do documento

@author Ewerton Alex Vicentin
@since 10/09/2026
@version P12
/*/
Static Function RetItDoc(cPostOri, cLocOri, cDocOri)

Local aRet     := {}
Local cAliasIt := GetNextAlias()

Default cPostOri := ""
Default cLocOri  := ""
Default cDocOri  := ""

BeginSql Alias cAliasIt
    SELECT
        ZI_DOC, ZI_ITEM, ZI_PRODUTO, ZI_PATRIM, ZI_NUMSER, ZI_ISSI, ZI_CODKIT, ZI_QUANT, ZI_LOCALIZ, ZI_DATAMOV, ZI_DESCRI, ZI_NUMSEQ
    FROM
        %Table:SZI% SZI
    WHERE
        SZI.ZI_FILIAL = %xFilial:SZI% AND
        SZI.ZI_CODPOST = %Exp:cPostOri% AND
        SZI.ZI_LOCALID = %Exp:cLocOri% AND
        SZI.ZI_DOC = %Exp:cDocOri% AND
        SZI.ZI_STATUS = 'A' AND
        SZI.%NotDel%
    ORDER BY SZI.ZI_ITEM
EndSql

While !(cAliasIt)->(EOF())
    AAdd(aRet, {(cAliasIt)->ZI_DOC    ,;
                (cAliasIt)->ZI_ITEM   ,;
                (cAliasIt)->ZI_PRODUTO,;
                (cAliasIt)->ZI_PATRIM ,;
                (cAliasIt)->ZI_NUMSER ,;
                (cAliasIt)->ZI_ISSI   ,;
                (cAliasIt)->ZI_CODKIT ,;
                (cAliasIt)->ZI_QUANT  ,;
                (cAliasIt)->ZI_LOCALIZ,;
                (cAliasIt)->ZI_DATAMOV,;
                (cAliasIt)->ZI_DESCRI ,;
                (cAliasIt)->ZI_NUMSEQ  })
    (cAliasIt)->(DbSkip())
End

(cAliasIt)->(DbCloseArea())

Return aRet

/*/{Protheus.doc} DlgTermos
Pergunta qual termo deve ser impresso apos a transferencia em lote.
Recebe a lista de pares gerados em AtuaLote:
{Doc.Origem, Novo Doc.Entrega, Doc.Devolucao, ZH_CODPOST, ZH_LOCALID}.
Sair do dialogo nao desfaz a gravacao ja confirmada.

@param aLote Lista de pares (documento original devolvido -> documento novo de entrega)
@return Nil

@author Ewerton Alex Vicentin
@since 10/09/2026
@version P12
/*/
Static Function DlgTermos(aLote)

Local oDlg
Local oSay1
Local oSay2
Local oRadio
Local oBtnImp
Local oBtnSai
Local aOpcoes := {"Entrega", "Devolução"}

Default aLote := {}

DEFINE MSDIALOG oDlg TITLE "Imprimir Termo?" FROM 000, 000 TO 145, 250 COLORS 0, 16777215 PIXEL

@ 005, 005 SAY oSay1 PROMPT "Selecione o termo que deseja imprimir:" SIZE 120, 007 OF oDlg COLORS 0, 16777215 PIXEL
@ 014, 005 SAY oSay2 PROMPT "Documentos transferidos: " + AllTrim(Str(Len(aLote))) SIZE 120, 007 OF oDlg COLORS 0, 16777215 PIXEL

// O 4o. parametro (bSetGet) e a unica fonte do estado: chamado com Nil devolve a opcao
// corrente, o que ja deixa a 1a. opcao marcada na montagem do objeto.
nRadOpc := 1
oRadio  := TRadMenu():New(026, 005, aOpcoes, {|u| RadOpc(u)}, oDlg,,,,,,,, 100, 025,,,, .T.)

@ 058, 032 BUTTON oBtnImp PROMPT "Imprimir" ACTION(ImpTermo(RadOpc(), aLote)) SIZE 037, 012 OF oDlg PIXEL
@ 058, 074 BUTTON oBtnSai PROMPT "Sair" ACTION(oDlg:End()) SIZE 037, 012 OF oDlg PIXEL

ACTIVATE MSDIALOG oDlg CENTERED

Return

/*/{Protheus.doc} RadOpc
Get/Set da opcao selecionada no radio de impressao dos termos.
Chamada sem parametro (ou com Nil, como o TRadMenu faz na montagem) devolve a opcao
corrente; chamada com um numero grava a nova opcao escolhida pelo usuario.

@param uOpc Opcao selecionada no radio (1 = Entrega, 2 = Devolucao)
@return nRadOpc Opcao corrente

@author Ewerton Alex Vicentin
@since 10/09/2026
@version P12
/*/
Static Function RadOpc(uOpc)

If uOpc <> Nil .And. ValType(uOpc) == "N" .And. uOpc > 0
	nRadOpc := uOpc
EndIf

Return nRadOpc

/*/{Protheus.doc} ImpTermo
Dispara a impressao do termo escolhido para cada documento do lote, sem fechar
o dialogo. Usa as mesmas UFs de termo chamadas pela TRAN01.

@param nOpc  Opcao escolhida (1 = Entrega, 2 = Devolucao)
@param aLote Lista {Doc.Origem, Novo Doc.Entrega, Doc.Devolucao, ZH_CODPOST, ZH_LOCALID}
@return Nil

@author Ewerton Alex Vicentin
@since 10/09/2026
@version P12
/*/
Static Function ImpTermo(nOpc, aLote)

Local nX := 0

Default nOpc  := 1
Default aLote := {}

If Empty(aLote)
    MsgInfo("Não há documentos gerados nessa transferência.", "Atenção")
    Return
EndIf

For nX := 1 To Len(aLote)
    If nOpc == 1
        If Empty(aLote[nX, 2])
            MsgInfo("Não há documento de entrega gerado para [" + AllTrim(aLote[nX, 1]) + "].", "Atenção")
        Else
            U_TermoEntr(aLote[nX, 4], aLote[nX, 5], aLote[nX, 2])
        EndIf
    ElseIf nOpc == 2
        If Empty(aLote[nX, 3])
            MsgInfo("Não há documento de devolução gerado para [" + AllTrim(aLote[nX, 1]) + "].", "Atenção")
        Else
            U_TermoDevol(aLote[nX, 4], aLote[nX, 5], aLote[nX, 3])
        EndIf
    EndIf
Next nX

Return


