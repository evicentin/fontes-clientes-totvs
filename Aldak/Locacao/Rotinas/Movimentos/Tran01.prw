#Include "totvs.ch"
#Include "fwmvcdef.ch"

/*/{Protheus.doc} TRAN01
Troca de gerência / centro de custo.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function TRAN01()

Local aDoc         := {}
Local aFields      := {}
Private cCodPost   := ""
Private cLocalid   := ""
Private cDocumento := ""
Private cCCusto    := ""
Private cResp      := ""
Private cNomeResp  := ""
Private cChamado   := ""
Private cMotivo    := ""
Private cNumSeq    := ""
Private cISSI      := ""
Private cAliasTmp  := GetNextAlias()
Private cAliasIt   := GetNextAlias()
Private aItens     := {}

SZ0->(DbSetOrder(1)) // Cod.Responsável
SZH->(DbSetOrder(2)) // Documento
SZI->(DbSetOrder(5)) // ISSI + Status
SZJ->(DbSetOrder(1)) // Cód.Posto + Localidade + Produto + Patrimônio
Z20->(DbSetOrder(1)) // Código

If !Pergunte("TRANSEQUIP", .T.)
	Return
EndIf

If !Empty(mv_par01)
    // aDoc[1] - ZI_DOC
    // aDoc[2] - ZI_STATUS
    // aDoc[3] - ZI_ISSI
    // aDoc[4] - ZI_NUMSEQ
    aDoc := U_RetDocPat(AllTrim(mv_par01))

    If Empty(aDoc[1])
        MsgInfo('Nenhum movimento ativo foi encontrado para esse Patrimônio.', "Atenção")
        Return
    EndIf

    If !SZH->(DbSeek(xFilial("SZH") + aDoc[1]))
        MsgInfo("Documento não encontrado!", "Atenção")
        Return
    EndIf
ElseIf !Empty(mv_par02)
    If !SZI->(DbSeek(xFilial("SZI") + mv_par02))
        MsgInfo("ISSI não encontrada!", "Atenção")
        Return
    Else
        If !SZH->(DbSeek(xFilial("SZH") + SZI->ZI_DOC))
            MsgInfo("Documento não encontrado!", "Atenção")
            Return
        EndIf
    EndIf
EndIf

If SZH->ZH_STATUS == "D"
    MsgInfo('Esse patrimônio já foi devolvido.', "Atenção")
    Return
EndIf

cCodPost   := SZH->ZH_CODPOST
cLocalid   := SZH->ZH_LOCALID
cDocumento := SZH->ZH_DOC
cCCusto    := SZH->ZH_CC
cResp      := SZH->ZH_CODRESP
cChamado   := SZH->ZH_CHAMADO
cMotivo    := SZH->ZH_MOTIVO
cNumSeq    := If(Empty(mv_par01), Posicione("SZI", 1, xFilial("SZI") + cCodPost + cLocalid + cDocumento, "ZI_NUMSEQ"), aDoc[4])
cISSI      := If(Empty(mv_par01), Posicione("SZI", 1, xFilial("SZI") + cCodPost + cLocalid + cDocumento, "ZI_ISSI"), aDoc[3])

If SZ0->(DbSeek(xFilial("SZ0") + cCodPost + cResp))
    cNomeResp := SZ0->Z0_NOME
EndIf

AAdd(aFields, {"ZH_CODPOST", "C",   6, 0})
AAdd(aFields, {"ZH_LOCALID", "C",   6, 0})
AAdd(aFields, {"ZH_DOC"    , "C",   6, 0})
AAdd(aFields, {"ZH_CC"     , "C",  30, 0})
AAdd(aFields, {"ZH_RESP"   , "C",  80, 0})
AAdd(aFields, {"ZH_CCNEW"  , "C",  30, 0})
AAdd(aFields, {"ZH_DESCCC" , "C", 180, 0})
AAdd(aFields, {"ZH_RESPNEW", "C",   6, 0})
AAdd(aFields, {"ZH_NOME"   , "C", 120, 0})

oTempTable := FWTemporaryTable():New(cAliasTmp, aFields)
oTempTable:AddIndex("1", {"ZH_CODPOST", "ZH_LOCALID", "ZH_DOC"} )
oTempTable:Create()

RecLock(cAliasTmp, .T.)
(cAliasTmp)->ZH_CODPOST := cCodPost
(cAliasTmp)->ZH_LOCALID := cLocalid
(cAliasTmp)->ZH_DOC     := cDocumento
(cAliasTmp)->ZH_CC      := cCCusto
(cAliasTmp)->ZH_RESP    := cNomeResp
MsUnlock()

FWExecView("", "TRAN01", MODEL_OPERATION_INSERT, , { || .T. })

If Select(cAliasIt)
    (cAliasIt)->(DbCloseArea())
EndIF

Return

/*/{Protheus.doc} MODELDEF
Modelo de Dados do MVC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ModelDef()

Local oModel
Local oStruTMP := FWFormModelStruct():New()

oStruTMP:AddTable(cAliasTmp, {"ZH_CODPOST", "ZH_LOCALID", "ZH_DOC", "ZH_RESP", "ZH_CCNEW", "ZH_DESCCC", "ZH_RESPNEW", "ZH_NOME"}, "SZHTEMP")

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

oStruTMP:AddField("Cod.Posto"  , "Cod.Posto"  , "ZH_CODPOST", "C",  6 , 0, Nil, {|| .T.}, {}, .F., {|| cCodPost}   , .F., .T., .F.)     
oStruTMP:AddField("Localidade" , "Localidade" , "ZH_LOCALID", "C",  6 , 0, Nil, {|| .T.}, {}, .F., {|| cLocalid}   , .F., .T., .F.)     
oStruTMP:AddField("Documento"  , "Documento"  , "ZH_DOC"    , "C", 30 , 0, Nil, {|| .T.}, {}, .F., {|| cDocumento} , .F., .T., .F.)     
oStruTMP:AddField("CC"         , "CC"         , "ZH_CC"     , "C", 30 , 0, Nil, {|| .T.}, {}, .F., {|| cCCusto}    , .F., .T., .F.)     
oStruTMP:AddField("Responsavel", "Responsavel", "ZH_RESP"   , "C", 80 , 0, Nil, {|| .T.}, {}, .F., {|| cNomeResp}  , .F., .T., .F.)     
oStruTMP:AddField("Novo CC"    , "Novo CC"    , "ZH_CCNEW"  , "C", 30 , 0, Nil, {|| .T.}, {}, .T., Nil             , .F., .T., .F.)     
oStruTMP:AddField("Desc.CC"    , "Desc.CC"    , "ZH_DESCCC" , "C", 180, 0, Nil, {|| .T.}, {}, .F., Nil             , .F., .T., .F.)     
oStruTMP:AddField("Novo Resp." , "Novo Resp." , "ZH_RESPNEW", "C", 6  , 0, Nil, {|| .T.}, {}, .T., Nil             , .F., .T., .F.)     
oStruTMP:AddField("Nome Resp." , "Nome Resp." , "ZH_NOME"   , "C", 120, 0, Nil, {|| .T.}, {}, .F., Nil             , .F., .T., .F.)     

oModel := MPFormModel():New("TRAN01M", /*bPreValidacao*/, /*bPosValidacao*/, {|oMdl| AtuaTransf(oMdl)}, /*bCancel*/)
oModel:AddFields("SZHTMP", /*cOwner*/ ,oStruTMP)

oModel:SetPrimaryKey({'ZH_DOC'})

oModel:SetDescription("Troca de Gerencia")
oModel:GetModel("SZHTMP"):SetDescription("Dados do Documento")

Return(oModel)

/*/{Protheus.doc} VIEWDEF
View do MVC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ViewDef()

Local oView
Local oStruTMP := FWFormViewStruct():New()
Local oModel     := FWLoadModel("TRAN01")

// [01]  C   Nome do Campo
// [02]  C   Ordem
// [03]  C   Titulo do campo
// [04]  C   Descricao do campo
// [05]  A   Array com Help
// [06]  C   Tipo do campo
// [07]  C   Picture
// [08]  B   Bloco de PictTre Var
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

oStruTmp:AddField("ZH_CODPOST", "01", "Cod.Posto"  , "Cod.Posto"  , Nil, "C", "@!", Nil, Nil  , .F., Nil, Nil, Nil, Nil, Nil, Nil, Nil, Nil)
oStruTmp:AddField("ZH_LOCALID", "02", "Localidade" , "Localidade" , Nil, "C", "@!", Nil, Nil  , .F., Nil, Nil, Nil, Nil, Nil, Nil, Nil, Nil)
oStruTmp:AddField("ZH_DOC"    , "03", "Documento"  , "Documento"  , Nil, "C", "@!", Nil, Nil  , .F., Nil, Nil, Nil, Nil, Nil, Nil, Nil, Nil)
oStruTmp:AddField("ZH_CC"     , "04", "C.Custo"    , "C.Custo"    , Nil, "C", "@!", Nil, Nil  , .F., Nil, Nil, Nil, Nil, Nil, Nil, Nil, Nil)
oStruTmp:AddField("ZH_RESP"   , "05", "Responsavel", "Responsavel", Nil, "C", "@!", Nil, Nil  , .F., Nil, Nil, Nil, Nil, Nil, Nil, Nil, Nil)
oStruTmp:AddField("ZH_CCNEW"  , "06", "Novo CC"    , "Novo CC"    , Nil, "C", "@!", Nil, "SZ5", .T., Nil, Nil, Nil, Nil, Nil, Nil, Nil, Nil)
oStruTmp:AddField("ZH_DESCCC" , "07", "Desc.CC"    , "Desc.CC"    , Nil, "C", "@!", Nil, Nil  , .F., Nil, Nil, Nil, Nil, Nil, Nil, Nil, .T.)
oStruTmp:AddField("ZH_RESPNEW", "08", "Novo Resp." , "Novo Resp." , Nil, "C", "@!", Nil, "SZ0", .T., Nil, Nil, Nil, Nil, Nil, Nil, Nil, Nil)
oStruTmp:AddField("ZH_NOME"   , "09", "Nome"       , "Nome"       , Nil, "C", "@!", Nil, Nil  , .F., Nil, Nil, Nil, Nil, Nil, Nil, Nil, Nil)

oView := FWFormView():New()

oView:SetModel(oModel)

oView:AddField("VIEWSZH", oStruTMP, "SZHTMP")

oView:SetCloseOnOk({|| .T.})

oView:CreateHorizontalBox("CABEC", 30)
oView:CreateHorizontalBox("ITENS", 70)

oView:AddOtherObject("BROWSE", {|oPanel| BrowseIt(oPanel)})

oView:SetOwnerView("VIEWSZH", "CABEC")
oView:SetOwnerView("BROWSE", "ITENS")

Return(oview)

/*/{Protheus.doc} BrowseIt
Carrega o BrowseIt.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function BrowseIt(oPanel)

Local oBrowse
Local nX       := 0
Local aTitles  := {"Documento","Item","Produto","Patrimônio","Num.Série","ISSI","KIT","Quantidade","Localização","Data Movimento","Descrição",;
                   "Num.Seq.","Doc.Orig."}
Local aFields  := {"ZI_DOC","ZI_ITEM","ZI_PRODUTO","ZI_PATRIM","ZI_NUMSER","ZI_ISSI","ZI_CODKIT","ZI_QUANT","ZI_LOCALIZ","ZI_DATAMOV",;
                   "ZI_DESCRI","ZI_NUMSEQ"}
Local aColumns := {}

BeginSql Alias cAliasIt
    SELECT 
        ZI_DOC, ZI_ITEM, ZI_PRODUTO, ZI_PATRIM, ZI_NUMSER, ZI_ISSI, ZI_CODKIT, ZI_QUANT, ZI_LOCALIZ, ZI_DATAMOV, ZI_DESCRI, ZI_NUMSEQ
    FROM
        %Table:SZI% SZI
    WHERE
        ZI_FILIAL = %xFilial:SZI% AND
        ZI_ISSI = %Exp:cISSI% AND
        ZI_STATUS = 'A' AND
        SZI.%NotDel%
        ORDER BY ZI_ITEM
EndSQL

If !(cAliasIt)->(EOF())
    (cAliasIt)->(DbGoTop())
    While !(cAliasIt)->(EOF())
        aAdd(aItens, {;
            ZI_DOC,;
            ZI_ITEM,;
            ZI_PRODUTO,;
            ZI_PATRIM,;
            ZI_NUMSER,;
            ZI_ISSI,;
            ZI_CODKIT,;
            ZI_QUANT,;
            ZI_LOCALIZ,;
            ZI_DATAMOV,;
            ZI_DESCRI,;
            ZI_NUMSEQ,;
        })
        (cAliasIt)->(DbSkip())
    End
    (cAliasIt)->(DbGoTop())
EndIf

For nX := 1 to Len(aFields)
    AAdd(aColumns, FWBrwColumn():New())

    aColumns[Len(aColumns)]:SetData(&("{||"+aFields[nX]+"}"))
    aColumns[Len(aColumns)]:SetTitle(aTitles[nX])
    aColumns[Len(aColumns)]:SetSize(TamSx3(aFields[nX])[1])
    aColumns[Len(aColumns)]:SetDecimal(TamSx3(aFields[nX])[2])
Next nX

oBrowse := FWMBrowse():New()
oBrowse:SetAlias(cAliasIt)
oBrowse:DisableFilter()
oBrowse:DisableConfig()
oBrowse:DisableReport()
oBrowse:DisableSeek()
oBrowse:DisableSaveConfig()
oBrowse:DisableDetails()
oBrowse:SetDataTable()
oBrowse:SetEditCell(.T., {|| .T.})
oBrowse:lHeaderClick := .F.
oBrowse:SetColumns(aColumns)
oBrowse:SetOwner(oPanel)

oBrowse:Activate()

Return

/*/{Protheus.doc} AtuaTransf
Grava a transferência.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function AtuaTransf(oModel)

Local nX         := 0
Local nOperation := oModel:GetOperation()
Local oModelSZH  := oModel:GetModel("SZHTMP")
Local cDoc       := ""
Local cNewDoc    := ""
Local cNewDev    := ""
Local cKit       := ""
Local cItem      := ""
Local cProduto   := ""
Local cPatrim    := ""
Local cNUmSer    := ""
Local nQuant     := 0
Local cNumSeq    := ""
Local cDescri    := ""
Local cLocaliz   := ""

SB1->(DbSetOrder(1)) // Codigo
SZI->(DbSetOrder(5)) // ISSI + Documento + Item
SZJ->(DbSetOrder(1)) // Cód.Posto + Localidade + Produto + Patrimônio
SZK->(DbSetOrder(1)) // Cliente + Loja + Patromônio

If nOperation == MODEL_OPERATION_INSERT
    BeginTran()

    // aItens
    // [1] - ZI_DOC
    // [2] - ZI_ITEM
    // [3] - ZI_PRODUTO
    // [4] - ZI_PATRIM
    // [5] - ZI_NUMSER
    // [6] - ZI_ISSI
    // [7] - ZI_CODKIT
    // [8] - ZI_QUANT
    // [9] - ZI_LOCALIZ
    // [10] - ZI_DATAMOV
    // [11] - ZI_DESCRI
    // [12] - ZI_NUMSEQ

    // Grava o documento de devolução.
    cNewDev := GetSXENum("SZH", "ZH_DOC")

    RecLock("SZH", .T.)
    SZH->ZH_FILIAL  := xFilial("SZH")
    SZH->ZH_DOC     := cNewDev
    SZH->ZH_EMISSAO := dDataBase
    SZH->ZH_CODPOST := cCodPost
    SZH->ZH_LOCALID := cLocalid
    SZH->ZH_CC      := cCCusto
    SZH->ZH_CODRESP := cResp
    SZH->ZH_CHAMADO := cChamado
    SZH->ZH_MOTIVO  := cMotivo
    SZH->ZH_STATUS  := "D"
    MsUnlock()

    For nX := 1 to Len(aItens)
        cItem     := aItens[nX, 2]
        cProduto  := aItens[nX, 3]
        cPatrim   := aItens[nX, 4]
        cNUmSer   := aItens[nX, 5]
        cISSI     := aItens[nX, 6]
        cKit      := aItens[nX, 7]
        nQuant    := aItens[nX, 8]
        cLocaliz  := aItens[nX, 9]
        cDescri   := aItens[nX, 11]
        cNumSeq   := aItens[nX, 12]

        // Grava o item devolvido.
        RecLock("SZI", .T.)
        SZI->ZI_FILIAL  := xFilial("SZI")
        SZI->ZI_CODPOST := cCodPost
        SZI->ZI_LOCALID := cLocalid
        SZI->ZI_DOC     := cNewDev
        SZI->ZI_STATUS  := "V" // Devolvido, sem effeito de medição, apenas para gerar o documento de devolução.
        SZI->ZI_ITEM    := cItem
        SZI->ZI_PRODUTO := cProduto
        SZI->ZI_PATRIM  := cPatrim
        SZI->ZI_NUMSER  := cNumSer
        SZI->ZI_ISSI    := cISSI
        SZI->ZI_CODKIT  := cKit
        SZI->ZI_QUANT   := nQuant
        SZI->ZI_LOCALIZ := cLocaliz
        SZI->ZI_DATAMOV := dDataBase
        SZI->ZI_DESCRI  := cDescri
        SZI->ZI_NUMSEQ  := cNumSeq
        MsUnlock()
    Next nX

    // Commit no cNewDev.
    ConfirmSX8()

    // Baixa os itens que estão sendo devolvidos no documento original de entrega.
    cNewDoc := GetSXENum("SZH", "ZH_DOC")

    For nX := 1 to Len(aItens)
        cDoc      := aItens[nX, 1]
        cItem     := aItens[nX, 2]
        cProduto  := aItens[nX, 3]
        cPatrim   := aItens[nX, 4]
        cISSI     := aItens[nX, 6]
        cNUmSer   := aItens[nX, 5]
        nQuant    := aItens[nX, 8]

        If SZI->(DbSeek(xFilial("SZI") + cISSI + cDoc + cItem))
            // Atualiza o status para devolvido.
            RecLock("SZI", .F.)
            SZI->ZI_STATUS  := "V" // Devolvido, sem efito, não entra na medição.
            SZI->ZI_DATADEV := CtoD("01/01/1990")
            SZI->ZI_PERDA   := 0
            SZI->ZI_DOCSUBS := cNewDev
            MsUnlock()
        EndIf
    Next nX

    // Grava o novo documento de transferência (Entrega).
    RecLock("SZH", .T.)
    SZH->ZH_FILIAL  := xFilial("SZH")
    SZH->ZH_DOC     := cNewDoc
    SZH->ZH_EMISSAO := dDataBase
    SZH->ZH_CODPOST := cCodPost
    SZH->ZH_LOCALID := cLocalid
    SZH->ZH_CC      := oModelSZH:GetValue("ZH_CCNEW")
    SZH->ZH_CODRESP := oModelSZH:GetValue("ZH_RESPNEW")
    SZH->ZH_CHAMADO := cChamado
    SZH->ZH_MOTIVO  := cMotivo
    SZH->ZH_STATUS  := "A"
    MsUnlock()

    For nX := 1 to Len(aItens)
        cItem     := aItens[nX, 2]
        cProduto  := aItens[nX, 3]
        cPatrim   := aItens[nX, 4]
        cNUmSer   := aItens[nX, 5]
        cISSI     := aItens[nX, 6]
        cKit      := aItens[nX, 7]
        nQuant    := aItens[nX, 8]
        cLocaliz  := aItens[nX, 9]
        cDescri   := aItens[nX, 11]
        cNumSeq   := aItens[nX, 12]

        // Grava o item novo.
        RecLock("SZI", .T.)
        SZI->ZI_FILIAL  := xFilial("SZI")
        SZI->ZI_CODPOST := cCodPost
        SZI->ZI_LOCALID := cLocalid
        SZI->ZI_DOC     := cNewDoc
        SZI->ZI_STATUS  := "A"
        SZI->ZI_ITEM    := cItem
        SZI->ZI_PRODUTO := cProduto
        SZI->ZI_PATRIM  := cPatrim
        SZI->ZI_NUMSER  := cNumSer
        SZI->ZI_ISSI    := cISSI
        SZI->ZI_CODKIT  := cKit
        SZI->ZI_QUANT   := nQuant
        SZI->ZI_LOCALIZ := cLocaliz
        SZI->ZI_DATAMOV := dDataBase
        SZI->ZI_DESCRI  := cDescri
        SZI->ZI_NUMSEQ  := cNumSeq
        MsUnlock()
    Next nX

    // Commit no cNewDoc.
    ConfirmSX8()

    Endtran()
EndIf

MsgInfo("Transferência concluída. Novo documento de entrega [" + cNewDoc + "] - Documento de devolução [" + cNewDev + "]",;
        "Atenção")


Return(.T.)
