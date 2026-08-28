#Include "totvs.ch"
#Include "fwmvcdef.ch"

// Posicoes do array de itens marcados montado por DevItens
#define POSITEM      1
#define POSPRODUTO   2
#define POSPATRIM    3
#define POSNUMSER    4
#define POSISSI      5
#define POSCODKIT    6
#define POSQUANT     7
#define POSPERDA     8
#define POSLOCALIZ   9
#define POSDATAMOV  10
#define POSDESCRI   11
#define POSNUMSEQ   12
#define POSDOCORI   13

/*/{Protheus.doc} MOVDEV
Substituiï¿½ï¿½o de Equipamentos.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function MOVDEV()

Local aAreaSZH     := FWGetArea()
Local nOpcView     := 0
Private oMark
Private oTempTable
Private cAliasTemp := GetNextAlias()
Private cCodPost   := ""
Private cLocalid   := ""
Private cDocumento := ""
Private cISSI      := ""
Private aDoc       := {}
Private cTpBusca   := "D" // "D" = documento posicionado, "P" = patrimônio (mv_par01), "I" = ISSI (mv_par02)

If !Pergunte("DEVOLEQUIP", .T.)
	Return
EndIf

SZH->(DbSetOrder(2)) // Documento
SZI->(DbSetOrder(5)) // ISSI + Status
SZJ->(DbSetOrder(1)) // Cód.Posto + Localidade + Produto + Patrimônio
Z20->(DbSetOrder(1)) // Código

If !Empty(mv_par01)
    // aDoc[1] - ZI_DOC
    // aDoc[2] - ZI_STATUS
    // aDoc[3] - ZI_ISSI
    // aDoc[4] - ZI_NUMSEQ
    cTpBusca := "P"

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
    cTpBusca := "I"

    If !SZI->(DbSeek(xFilial("SZI") + AllTrim(mv_par02)))
        MsgInfo("ISSI não encontrada!", "Atenção")
        Return
    Else
        While SZI->ZI_ISSI == mv_par02 .and. !SZI->(EOF())
            If !Empty(SZI->ZI_PATRIM) .and. SZI->ZI_STATUS == "A"
                cDocumento := SZI->ZI_DOC
                cISSI      := SZI->ZI_ISSI
                Exit
            EndIf
            SZI->(DbSkip())
        End

        If !SZH->(DbSeek(xFilial("SZH") + cDocumento))
            MsgInfo("Documento não encontrado!", "Atenção")
            Return
        EndIf
    EndIf
EndIf

If SZH->ZH_STATUS == "D"
    MsgInfo('Esse documento já foi devolvido.', "Atenção")
    Return
EndIf

// Somente o estado necessario para montar o MarkBrowse; o cabecalho da gravacao vem do modelo (MdvCommit / AtuaMov).
cCodPost   := SZH->ZH_CODPOST
cLocalid   := SZH->ZH_LOCALID
cDocumento := SZH->ZH_DOC
cISSI      := If(cTpBusca == "P", PadR(aDoc[3], TamSX3("ZI_ISSI")[1]), If(cTpBusca == "I", cISSI, ""))

nOpcView := FWExecView("", "MOVDEV", MODEL_OPERATION_UPDATE, , { || .T. })

If nOpcView == 0
    MsgInfo("Devolução concluída.", "Atenção")
EndIf

If oTempTable <> Nil
    oTempTable:Delete()
    FreeObj(oTempTable)
EndIf

If oMark <> Nil
    oMark:DeActivate()
    FreeObj(oMark)
EndIf

FWrestArea(aAreaSZH)

Return

/*/{Protheus.doc} MODELDEF
Modelo de Dados do MVC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ModelDef()

Local oModel
Local oStruSZH := FWFormStruct(1, "SZH")

oModel := MPFormModel():New("MOVDEVM", /*bPre*/, {|oModel| MovTudoOk(oModel)}, {|oMdl| MdvCommit(oMdl)}, /*bCancel*/)

// Ponto UNICO de gravacao: cabecalho (FwFormCommit) + devolucao (AtuaMov) na mesma transacao.
oStruSZH:SetProperty("ZH_DOC", MODEL_FIELD_WHEN, FwBuildFeature(STRUCT_FEATURE_WHEN, ".F."))
oStruSZH:SetProperty("ZH_EMISSAO", MODEL_FIELD_WHEN, FwBuildFeature(STRUCT_FEATURE_WHEN, ".F."))
oStruSZH:SetProperty("ZH_CODPOST", MODEL_FIELD_WHEN, FwBuildFeature(STRUCT_FEATURE_WHEN, ".F."))
oStruSZH:SetProperty("ZH_LOCALID", MODEL_FIELD_WHEN, FwBuildFeature(STRUCT_FEATURE_WHEN, ".F."))
oStruSZH:SetProperty("ZH_CC", MODEL_FIELD_WHEN, FwBuildFeature(STRUCT_FEATURE_WHEN, ".F."))
oStruSZH:SetProperty("ZH_CODRESP", MODEL_FIELD_WHEN, FwBuildFeature(STRUCT_FEATURE_WHEN, ".F."))

oModel:AddFields("SZHMASTER",, oStruSZH)

oModel:SetPrimaryKey({"ZH_FILIAL", "ZH_DOC"})

// Apos a carga dos dados, zera Motivo e Chamado para digitacao no formulario.
oModel:SetActivate({|oMdl| MdvLoad(oMdl)})

oModel:SetDescription("Devolução")
oModel:GetModel("SZHMASTER"):SetDescription("Dados do Documento")

Return(oModel)

/*/{Protheus.doc} VIEWDEF
View do MVC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ViewDef()

Local oView
Local oStruSZH := FWFormStruct(2, "SZH", {|cCampo| !AllTrim(cCampo)+"|"$ "ZH_STATUS|ZH_DOC|ZH_EMISSAO|ZH_DPSCM|"})
Local oModel   := FWLoadModel("MOVDEV")

oView := FWFormView():New()

oView:SetModel(oModel)

oView:AddField("VIEW_SZH", oStruSZH, "SZHMASTER")

oView:SetCloseOnOk({|| .T.})

oView:CreateHorizontalBox("CABEC", 30)
oView:CreateHorizontalBox("ITENS", 70)

oView:AddOtherObject("MBROWSE", {|oPanel| MarkBrowse(oPanel)})

oView:SetOwnerView("VIEW_SZH", "CABEC")
oView:SetOwnerView("MBROWSE", "ITENS")

Return(oview)

/*/{Protheus.doc} MdvLoad
Bloco do SetActivate do modelo: roda logo APOS o AddFields carregar o registro
do SZH posicionado (MODEL_OPERATION_UPDATE).

Como o MODEL_FIELD_INIT so e avaliado em MODEL_OPERATION_INSERT, o Motivo e o
Chamado ja gravados no documento original viriam preenchidos na tela. Aqui eles
sao zerados para que o usuario informe os dados desta Devolucao.

Usa LoadValue (e nao SetValue) de proposito: e carga inicial controlada e o valor
em branco nao deve disparar validacao / gatilho de campo obrigatorio na abertura
da tela. A obrigatoriedade continua sendo criticada em MovTudoOk.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12

@param oModel, object, Modelo de dados ativo (MPFormModel "MOVDEVM") recebido pelo SetActivate.

@return logical, .T. sempre, para nao impedir a ativacao do modelo.
/*/
Static Function MdvLoad(oModel)

Local oModelSZH := Nil

If oModel == Nil
    oModel := FWModelActive()
EndIf

If oModel == Nil
    Return(.T.)
EndIf

oModelSZH := oModel:GetModel("SZHMASTER")

If oModelSZH == Nil
    Return(.T.)
EndIf

oModelSZH:LoadValue("ZH_MOTIVO" , Space(TamSX3("ZH_MOTIVO")[1]))
oModelSZH:LoadValue("ZH_CHAMADO", Space(TamSX3("ZH_CHAMADO")[1]))

Return(.T.)

/*/{Protheus.doc} MovTudoOk
Validaï¿½ï¿½o geral do modelo (TudoOk).
Exige o preenchimento do Motivo e do Chamado no cabeï¿½alho.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function MovTudoOk(oModel)

Local oModelSZH := Nil
Local lRet      := .T.

If oModel == Nil
    Return(.T.)
EndIf

oModelSZH := oModel:GetModel("SZHMASTER")

If oModelSZH == Nil
    Return(.T.)
EndIf

If Empty(oModelSZH:GetValue("ZH_MOTIVO"))
    MsgInfo("Informe o Motivo da Devolução.", "Atenção")
    lRet := .F.
EndIf

If lRet .and. Empty(oModelSZH:GetValue("ZH_CHAMADO"))
    MsgInfo("Informe o Chamado da Devolução.", "Atenção")
    lRet := .F.
EndIf

// Pre-condicoes que antes so eram criticadas dentro do botao "Devolver":
// acessorios do patrimonio marcados em conjunto e ao menos um item marcado.
// No ciclo do modelo a recusa ocorre ANTES de qualquer gravacao.
If lRet .and. oMark != Nil .and. Select(cAliasTemp) > 0
    lRet := DevValid(oModel, cAliasTemp, oMark:Mark())
EndIf

Return(lRet)

/*/{Protheus.doc} MdvCommit
Ponto UNICO de gravacao da Devolucao (bCommit do modelo, via SetCommitFunction).

Fluxo transacional:
1) revalida as criticas de negocio (DevValid) antes de qualquer escrita;
2) monta o array de itens marcados (DevItens), desacoplando a gravacao do browse;
3) abre UMA transacao (Begin Transaction) e nela executa:
   - FwFormCommit(oModel): grava ZH_MOTIVO / ZH_CHAMADO no documento ORIGINAL;
   - AtuaMov(oModel, aItens): gera o SZH de devolucao, os itens SZI "V",
     baixa os itens SZI "D", registra perdas em SZM, atualiza ZJ_LOCADO em SZJ
     e movimenta os estoques "02" / "03" via U_GravaEst.
Qualquer falha em AtuaMov dispara DisarmTransaction: nada e gravado (rollback
total), o erro sobe pelo modelo (SetErrorMessage) e o formulario permanece aberto.
Nao ha gravacao direta do cabecalho original fora do FwFormCommit.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12

@param oModel, object, Modelo de dados ativo (MPFormModel "MOVDEVM") recebido pelo bCommit.

@return logical, .T. quando cabecalho e devolucao foram gravados na mesma transacao; .F. aborta o commit e mantem a view aberta.
/*/
Static Function MdvCommit(oModel)

Local aAreaSZH  := FWGetArea()
Local oModelSZH := Nil
Local aItens    := {}
Local cMarca    := ""
Local lRet      := .T.

If oModel == Nil
    Return(DevErro(oModel, "Modelo de dados da Devolução não localizado."))
EndIf

oModelSZH := oModel:GetModel("SZHMASTER")

If oModelSZH == Nil
    Return(DevErro(oModel, "Cabeçalho do documento (SZHMASTER) não localizado."))
EndIf

If oMark == Nil .or. Select(cAliasTemp) == 0
    Return(DevErro(oModel, "Itens da Devolução não estão disponíveis para gravação."))
EndIf

cMarca := oMark:Mark()

// Rede de protecao: as mesmas criticas de MovTudoOk, caso o commit seja disparado
// sem passar pelo TudoOk (o usuario ja viu a mensagem antes de qualquer gravacao).
If !DevValid(oModel, cAliasTemp, cMarca)
    FWRestArea(aAreaSZH)
    Return(.F.)
EndIf

aItens := DevItens(cAliasTemp, cMarca)

Begin Transaction

    // Cabecalho do documento original (ZH_MOTIVO / ZH_CHAMADO) pelo proprio modelo.
    FwFormCommit(oModel)

    lRet := AtuaMov(oModel, aItens)

    If !lRet
        DisarmTransaction()
    EndIf

End Transaction

If lRet
    // Mantem o documento do fluxo alinhado com o que foi confirmado na tela.
    cDocumento := oModelSZH:GetValue("ZH_DOC")
EndIf

FWRestArea(aAreaSZH)

Return(lRet)

/*/{Protheus.doc} MarkBrowse
Carrega o MarkBrowse.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function MarkBrowse(oPanel)

Local nX       := 0
Local aTitles  := {"Item","Produto","Patrimônio","Num.Série","ISSI","KIT","Quantidade","Perda","Localização","Data Movimento","Descrição",;
                   "Num.Seq.","Doc.Orig."}
Local aFields  := {}
Local aColumns := {}

// Estrutura da tabela temporï¿½ria.
AAdd(aFields, {"ZI_ITEM"   , "C",   3, 0})
AAdd(aFields, {"ZI_PRODUTO", "C",  30, 0})
AAdd(aFields, {"ZI_PATRIM" , "C",  20, 0})
AAdd(aFields, {"ZI_NUMSER" , "C",  25, 0})
AAdd(aFields, {"ZI_ISSI"   , "C",  14, 0})
AAdd(aFields, {"ZI_CODKIT" , "C",   6, 0})
AAdd(aFields, {"ZI_QUANT"  , "N",   5, 0})
AAdd(aFields, {"ZI_PERDA"  , "N",   5, 0})
AAdd(aFields, {"ZI_LOCALIZ", "C",  80, 0})
AAdd(aFields, {"ZI_DATAMOV", "D",   8, 0})
AAdd(aFields, {"ZI_DESCRI" , "C", 120, 0})
AAdd(aFields, {"ZI_NUMSEQ" , "C",   6, 0})
AAdd(aFields, {"ZI_DOCORI" , "C",   6, 0})
AAdd(aFields, {"ZI_OK"     , "C",   2, 0})

oTempTable := FWTemporaryTable():New(cAliasTemp, aFields)
oTempTable:AddIndex("1", {"ZI_ITEM"})
oTempTable:Create()

// Carrega o documento a ser devolvido.
MdvCarga(cAliasTemp)

// Monta as colunas do markbrowse.
For nX := 1 to Len(aFields)-1
    AAdd(aColumns, FWBrwColumn():New())

    aColumns[Len(aColumns)]:SetData(&("{||"+aFields[nX][1]+"}"))
    aColumns[Len(aColumns)]:SetTitle(aTitles[nX])
    aColumns[Len(aColumns)]:SetSize(aFields[nX][3])
    aColumns[Len(aColumns)]:SetDecimal(aFields[nX][4])

    If aFields[nX, 1] == "ZI_PERDA"
        aColumns[Len(aColumns)]:SetEdit(.T.)
        aColumns[Len(aColumns)]:SetReadVar(aFields[nX, 1])
    EndIf
Next nX

// Monta o markbrowse.
oMark := FWMarkBrowse():New()

oMark:SetAlias(cAliasTemp)
oMark:SetTemporary(.T.)
oMark:SetColumns(aColumns)
oMark:SetMenuDef("")
oMark:DisableConfig()
oMark:DisableFilter()
oMark:DisableLocate()
oMark:DisableSeek()
oMark:DisableReport()
oMark:DisableSaveConfig()
oMark:SetIgnoreARotina(.T.)
oMark:SetSeeAll(.F.)
oMark:SetChgAll(.F.)
oMark:SetFieldMark("ZI_OK")

// Ao marcar / desmarcar um item de patrimonio, replica a marca para todos os
// itens da mesma ISSI.
oMark:SetAfterMark({|cMarca| MarcaPat(cMarca)})

// oMark:AllMark() 

// A gravacao da devolucao ocorre exclusivamente no Confirmar do MVC (MdvCommit -> AtuaMov).
// O browse apenas marca os itens e permite digitar a perda.
oMark:AddButton("Perda", {|| Perda()})

oMark:SetOwner(oPanel)

oMark:Activate()

Return

/*/{Protheus.doc} MdvCarga
Carga dos itens ativos do SZI na tabela temporaria do MarkBrowse.

Quando a rotina entra sem parametros (cTpBusca == "D"), a carga passa a ser
feita pelo DOCUMENTO posicionado (ordem 1 do SZI: Cod.Posto+Localidade+
Documento+Item), trazendo TODOS os patrimonios / ISSIs daquele documento.
Nas entradas por Patrimonio (mv_par01) ou por ISSI (mv_par02) o comportamento
anterior e mantido: ordem 5 (ISSI+Documento+Item) filtrando pela ISSI.

Somente itens com ZI_STATUS == "A" sao carregados e ZI_DOCORI recebe o
SZI->ZI_DOC do item, pois e o documento de origem usado por AtuaMov na baixa.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12

@param cAlias, character, Alias da tabela temporaria do MarkBrowse (cAliasTemp).

@return logical, .T. sempre, apenas para permitir uso em bloco de codigo.
/*/
Static Function MdvCarga(cAlias)

Local aArea  := FWGetArea()
Local lSeek  := .F.
Local lSegue := .F.

If cTpBusca == "D"
    SZI->(DbSetOrder(1)) // Cod.Posto + Localidade + Documento + Item
    lSeek := SZI->(DbSeek(xFilial("SZI") + cCodPost + cLocalid + cDocumento))
Else
    SZI->(DbSetOrder(5)) // ISSI + Documento + Item
    lSeek := SZI->(DbSeek(xFilial("SZI") + cISSI))
EndIf

If lSeek
    lSegue := .T.

    While lSegue .and. !SZI->(EOF())

        If cTpBusca == "D"
            lSegue := SZI->ZI_FILIAL == xFilial("SZI") .and.;
                      SZI->ZI_CODPOST == cCodPost .and.;
                      SZI->ZI_LOCALID == cLocalid .and.;
                      SZI->ZI_DOC == cDocumento
        Else
            lSegue := SZI->ZI_FILIAL == xFilial("SZI") .and.;
                      SZI->ZI_ISSI == cISSI
        EndIf

        If !lSegue
            Exit
        EndIf

        If SZI->ZI_STATUS == "A"
            RecLock(cAlias, .T.)
            (cAlias)->ZI_ITEM    := SZI->ZI_ITEM
            (cAlias)->ZI_PRODUTO := SZI->ZI_PRODUTO
            (cAlias)->ZI_PATRIM  := SZI->ZI_PATRIM
            (cAlias)->ZI_NUMSER  := SZI->ZI_NUMSER
            (cAlias)->ZI_ISSI    := SZI->ZI_ISSI
            (cAlias)->ZI_CODKIT  := SZI->ZI_CODKIT
            (cAlias)->ZI_QUANT   := SZI->ZI_QUANT
            (cAlias)->ZI_LOCALIZ := SZI->ZI_LOCALIZ
            (cAlias)->ZI_DATAMOV := SZI->ZI_DATAMOV
            (cAlias)->ZI_DESCRI  := SZI->ZI_DESCRI
            (cAlias)->ZI_NUMSEQ  := SZI->ZI_NUMSEQ
            (cAlias)->ZI_DOCORI  := SZI->ZI_DOC
            MsUnlock()
        EndIf

        SZI->(DbSkip())
    End
EndIf

// A partir daqui o fluxo (AtuaMov) trabalha com a ordem ISSI+Documento+Item.
SZI->(DbSetOrder(5))

FWRestArea(aArea)

Return(.T.)

/*/{Protheus.doc} MarcaPat
Marca todos quando selecionar o patrimônio.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function MarcaPat(cMarca)

Local aAreaMark := (cAliasTemp)->(GetArea())
Local cISSIAtu  := (cAliasTemp)->ZI_ISSI
Local cPatAtu   := (cAliasTemp)->ZI_PATRIM
Local lMarcar   := .F.

Default cMarca  := oMark:Mark()

// So replica a marcacao quando o item selecionado e um patrimonio com ISSI.
If Empty(cPatAtu) .or. Empty(cISSIAtu)
    FWRestArea(aAreaMark)
    Return(.T.)
EndIf

// Estado atual do item clicado define se marca ou desmarca os demais da ISSI.
lMarcar := !Empty((cAliasTemp)->ZI_OK)

(cAliasTemp)->(DbGoTop())

While !(cAliasTemp)->(Eof())

    If (cAliasTemp)->ZI_ISSI == cISSIAtu
        RecLock((cAliasTemp), .F.)
        (cAliasTemp)->ZI_OK := If(lMarcar, cMarca, '  ')
        MsUnLock()
    EndIf

    (cAliasTemp)->(DbSkip())
EndDo

FWRestArea(aAreaMark)

oMark:Refresh(.T.)

Return(.T.)

/*/{Protheus.doc} SetMarkAll
Marcar / Desmarcar todos quando clicar no header.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function SetMarkAll(cMarca, lMarcar)

Local aAreaMark  := (cAliasTemp)->( GetArea())

(cAliasTemp)->(DbGoTop())

While !(cAliasTemp)->(Eof())
	RecLock( (cAliasTemp), .F.)
	(cAliasTemp)->ZI_OK := If(lMarcar, cMarca, '  ')
	MsUnLock()
	(cAliasTemp)->(DbSkip())
EndDo

RestArea(aAreaMark)

oMark:Refresh(.T.)

Return(.T.)

/*/{Protheus.doc} Perda
Digitação da perda.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function Perda()

Local oButton1
Local oButton2
Local oGet1
Local oSay1
Local oDlg
Local nPerda := 0
Local nOpc   := 0

DEFINE MSDIALOG oDlg TITLE "Perda" FROM 000, 000  TO 100, 180 COLORS 0, 16777215 PIXEL

@ 006, 005 SAY oSay1 PROMPT "Qtd.Perda" SIZE 030, 007 OF oDlg COLORS 0, 16777215 PIXEL
@ 015, 005 MSGET oGet1 VAR nPerda SIZE 060, 010 OF oDlg COLORS 0, 16777215 PIXEL
@ 034, 005 BUTTON oButton1 PROMPT "Cancelar" ACTION(nOpc := 0, oDlg:End()) SIZE 037, 012 OF oDlg PIXEL
@ 034, 047 BUTTON oButton2 PROMPT "Confirmar" ACTION(nOpc := 1, oDlg:End()) SIZE 037, 012 OF oDlg PIXEL

ACTIVATE MSDIALOG oDlg CENTERED

If nOpc == 1
    RecLock((cAliasTemp), .F.)
    (cAliasTemp)->ZI_PERDA := nPerda
    MsUnlock()

    oMark:Refresh()
EndIf

Return

/*/{Protheus.doc} AtuaMov
Gravacao da Devolucao (corpo migrado do antigo botao "Devolver" do MarkBrowse).
@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12

@param oModel, object, Modelo de dados ativo; se Nil, recupera via FWModelActive().
@param aItens, array, Itens marcados montados por DevItens (posicoes POSITEM..POSDOCORI).

@return logical, .T. quando a devolucao foi gravada; .F. quando alguma critica impede a gravacao.
/*/
Static Function AtuaMov(oModel, aItens)

Local oModelSZH := Nil
Local aArea     := FWGetArea()
Local aItem     := Nil
Local nX        := 0
Local cItem     := ""
Local cProduto  := ""
Local cPatrim   := ""
Local cISSIIt   := ""
Local cNumSer   := ""
Local cDocOri   := ""
Local cNewDoc   := ""
Local cCodPos   := ""
Local cLocaliz  := ""
Local cCCusAtu  := ""
Local cRespAtu  := ""
Local cChamAtu  := ""
Local cMotAtu   := ""
Local cDocAtu   := ""
Local nQuant    := 0
Local nPerda    := 0
Local lRet      := .T.

If oModel == Nil
    oModel := FWModelActive()
EndIf

If oModel == Nil
    Return(DevErro(oModel, "Modelo de dados da Devolução não localizado."))
EndIf

oModelSZH := oModel:GetModel("SZHMASTER")

If oModelSZH == Nil
    Return(DevErro(oModel, "Cabeçalho do documento (SZHMASTER) não localizado."))
EndIf

If aItens == Nil .or. Len(aItens) == 0
    Return(DevErro(oModel, "Selecione ao menos um item para ser devolvido."))
EndIf

cDocAtu  := oModelSZH:GetValue("ZH_DOC")
cCodPos  := oModelSZH:GetValue("ZH_CODPOST")
cLocaliz := oModelSZH:GetValue("ZH_LOCALID")
cCCusAtu := oModelSZH:GetValue("ZH_CC")
cRespAtu := oModelSZH:GetValue("ZH_CODRESP")
cChamAtu := oModelSZH:GetValue("ZH_CHAMADO")
cMotAtu  := oModelSZH:GetValue("ZH_MOTIVO")

SZI->(DbSetOrder(5)) // ISSI + Documento + Item
SZJ->(DbSetOrder(1)) // Cód.Posto + Localidade + Produto + Patrimônio

// Grava o documento de Devolução (a transacao e aberta pelo chamador).
cNewDoc := GetSXENum("SZH", "ZH_DOC")

RecLock("SZH", .T.)
SZH->ZH_FILIAL  := xFilial("SZH")
SZH->ZH_DOC     := cNewDoc
SZH->ZH_EMISSAO := dDataBase
SZH->ZH_CODPOST := cCodPos
SZH->ZH_LOCALID := cLocaliz
SZH->ZH_CC      := cCCusAtu
SZH->ZH_CODRESP := cRespAtu
SZH->ZH_CHAMADO := cChamAtu
SZH->ZH_MOTIVO  := cMotAtu
SZH->ZH_STATUS  := "D"
MsUnlock()

// Grava os itens novos do documento de Devolução.
For nX := 1 To Len(aItens)
    aItem := aItens[nX]

    RecLock("SZI", .T.)
    SZI->ZI_FILIAL  := xFilial("SZI")
    SZI->ZI_CODPOST := cCodPos
    SZI->ZI_LOCALID := cLocaliz
    SZI->ZI_DOC     := cNewDoc
    SZI->ZI_STATUS  := "V" // Devolvido, sem effeito de medição, apenas para gerar o documento de Devolução.
    SZI->ZI_ITEM    := aItem[POSITEM]
    SZI->ZI_PRODUTO := aItem[POSPRODUTO]
    SZI->ZI_PATRIM  := aItem[POSPATRIM]
    SZI->ZI_NUMSER  := aItem[POSNUMSER]
    SZI->ZI_ISSI    := aItem[POSISSI]
    SZI->ZI_CODKIT  := aItem[POSCODKIT]
    SZI->ZI_QUANT   := aItem[POSQUANT]
    SZI->ZI_PERDA   := aItem[POSPERDA]
    SZI->ZI_LOCALIZ := aItem[POSLOCALIZ]
    SZI->ZI_DATAMOV := aItem[POSDATAMOV]
    SZI->ZI_DESCRI  := aItem[POSDESCRI]
    SZI->ZI_NUMSEQ  := aItem[POSNUMSEQ]
    MsUnlock()
Next nX

// Baixa os itens que estáo sendo devolvidos mo documento original de entrega.
For nX := 1 To Len(aItens)
    aItem := aItens[nX]

    cDocOri   := aItem[POSDOCORI]
    cItem     := aItem[POSITEM]
    cProduto  := aItem[POSPRODUTO]
    cPatrim   := aItem[POSPATRIM]
    cNumSer   := aItem[POSNUMSER]
    cISSIIt   := aItem[POSISSI]
    nQuant    := aItem[POSQUANT] - aItem[POSPERDA]
    nPerda    := aItem[POSPERDA]

    If SZI->(DbSeek(xFilial("SZI") + cISSIIt + cDocOri + cItem))
        // Tem saldo para devolver, registra.
        If nQuant > 0
            U_GravaEst(cCodPos, cLocaliz, cProduto, "02", nQuant, "E")
        EndIf

        // Tem perda, registra o movimento no estoque de perdas.
        If nPerda > 0
            U_GravaEst(cCodPos, cLocaliz, cProduto, "03", nPerda, "E")

            // Registra no arquivo de perdas.
            RecLock("SZM", .T.)
            SZM->ZM_FILIAL  := xFilial("SZM")
            SZM->ZM_CODPOST := cCodPos
            SZM->ZM_LOCALID := cLocaliz
            SZM->ZM_DOC     := cDocAtu
            SZM->ZM_DATA    := dDataBase
            SZM->ZM_ITEM    := cItem
            SZM->ZM_PRODUTO := cProduto
            SZM->ZM_PATRIM  := cPatrim
            SZM->ZM_NUMSER  := cNumSer
            SZM->ZM_QUANT   := nPerda
            MsUnlock()
        EndIf

        // Atualiza o status para devolvido.
        RecLock("SZI", .F.)
        SZI->ZI_STATUS  := "D" // Devolvido, documento original entra na medição.
        SZI->ZI_DATADEV := dDataBase
        SZI->ZI_PERDA   := nPerda
        SZI->ZI_DOCSUBS := cNewDoc
        MsUnlock()

        If !Empty(cPatrim)
            If SZJ->(DbSeek(xFilial("SZJ") + cCodPos + cLocaliz + cProduto + cPatrim))
                RecLock("SZJ", .F.)
                // não teve perda, devolve o patrimônio para ser locado.
                If nPerda == 0
                    SZJ->ZJ_LOCADO := "M"
                Else
                    // Teve perda, inutiliza o patrimônio.
                    SZJ->ZJ_LOCADO := "P"
                EndIf
                MsUnlock()
            EndIf
        EndIf
    EndIf
Next nX

ConfirmSX8()

FWRestArea(aArea)

// Sem mensagem propria de sucesso: quem conclui e fecha a tela e o ciclo do MVC.
Return(lRet)

/*/{Protheus.doc} DevValid
Validacoes que antes ficavam dentro de AtuaMov (acessorios do patrimonio e ao menos um item marcado).

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function DevValid(oModel, cAlias, cMarca)

Local aArea   := (cAlias)->(GetArea())
Local aIssi   := {}
Local cIssi   := ""
Local nTotReg := 0
Local lRet    := .T.

// Levanta as ISSI dos patrimônios marcados para Devolução (o browse pode trazer
// varios patrimonios quando a rotina e aberta com os parametros em branco).
(cAlias)->(DbGoTop())
While !(cAlias)->(EOF())
    If (cAlias)->ZI_OK == cMarca
        nTotReg++

        cIssi := AllTrim((cAlias)->ZI_ISSI)

        If !Empty((cAlias)->ZI_PATRIM) .and. !Empty(cIssi) .and. AScan(aIssi, {|x| x == cIssi}) == 0
            AAdd(aIssi, cIssi)
        EndIf
    EndIf

    (cAlias)->(DbSkip())
End

// Somente os itens que pertencem as ISSI dos patrimonios marcados sao cobrados.
// Itens de outras ISSI (outros patrimonios ou avulsos) nao entram na validacao.
If Len(aIssi) > 0
    (cAlias)->(DbGoTop())
    While lRet .and. !(cAlias)->(EOF())
        cIssi := AllTrim((cAlias)->ZI_ISSI)

        If Empty((cAlias)->ZI_PATRIM) .and. !Empty(cIssi) .and.;
           AScan(aIssi, {|x| x == cIssi}) > 0 .and. (cAlias)->ZI_OK <> cMarca

            lRet := DevErro(oModel, "Quando o patrimônio está marcado para Devolução todos os acessórios da ISSI " + cIssi + " devem ser devolvidos.")
        EndIf

        (cAlias)->(DbSkip())
    End
EndIf

If lRet .and. Empty(nTotReg)
    lRet := DevErro(oModel, "Selecione ao menos um item para ser devolvido.")
EndIf

RestArea(aArea)

Return(lRet)

/*/{Protheus.doc} DevItens
Extrai do alias temporario os itens marcados, para AtuaMov nao depender do browse.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function DevItens(cAlias, cMarca)

Local aArea  := (cAlias)->(GetArea())
Local aItens := {}

(cAlias)->(DbGoTop())
While !(cAlias)->(EOF())
    If (cAlias)->ZI_OK == cMarca
        AAdd(aItens, {(cAlias)->ZI_ITEM   ,;
                      (cAlias)->ZI_PRODUTO,;
                      (cAlias)->ZI_PATRIM ,;
                      (cAlias)->ZI_NUMSER ,;
                      (cAlias)->ZI_ISSI   ,;
                      (cAlias)->ZI_CODKIT ,;
                      (cAlias)->ZI_QUANT  ,;
                      (cAlias)->ZI_PERDA  ,;
                      (cAlias)->ZI_LOCALIZ,;
                      (cAlias)->ZI_DATAMOV,;
                      (cAlias)->ZI_DESCRI ,;
                      (cAlias)->ZI_NUMSEQ ,;
                      (cAlias)->ZI_DOCORI })
    EndIf

    (cAlias)->(DbSkip())
End

RestArea(aArea)

Return(aItens)

/*/{Protheus.doc} DevErro
Sobe o erro pelo modelo (SetErrorMessage) quando ha modelo ativo; senao usa Help.
Sempre retorna .F. para o chamador abortar a gravacao.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function DevErro(oModel, cMsg)

If oModel != Nil
    oModel:SetErrorMessage("SZHMASTER",, "SZHMASTER",, "MOVDEV", cMsg, "Verifique os itens marcados e o cabeçalho da Devolução.")
Else
    Help(,, "MOVDEV",, cMsg, 1, 0)
EndIf

Return(.F.)
 