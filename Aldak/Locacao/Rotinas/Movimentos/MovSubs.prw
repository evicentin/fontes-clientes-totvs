#Include "totvs.ch"
#Include "fwmvcdef.ch"

/*/{Protheus.doc} MOVSUBS
Substituição de Equipamentos.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function MOVSUBS()

Private cCodPost   := ""
Private cLocalid   := ""
Private cDocumento := ""
Private cCCusto    := ""
Private cResp      := ""
Private cMotivo    := ""
Private cNumSeq    := ""
Private cISSI      := ""
Private aDoc       := {}
Private lAddLine   := .F.

// Mapa das linhas substitutas x patrimonio original referenciado.
// aRefSubs[n][1] - Linha do grid SZISUBST
// aRefSubs[n][2] - Item do documento original (ZI_ITEM)
// aRefSubs[n][3] - Patrimonio original (ZI_PATRIM)
// aRefSubs[n][4] - ISSI do patrimonio original (ZI_ISSI)
// aRefSubs[n][5] - Agrupador do kit (mesma chamada de LoadKit)
// aRefSubs[n][6] - .T. quando a linha e a ancora (item pai) do agrupamento
// aRefSubs[n][7] - Documento de origem do item substituido (ZI_DOC)
Private aRefSubs   := {}

// Sequencial usado para gerar o agrupador de cada kit carregado.
Private nSeqGrup   := 0

SZH->(DbSetOrder(2))

If !Pergunte("SUBSTEQUIP", .T.)
	Return
EndIf

// Substituição de acessórios (mv_par01 == 3) é sempre filtrada pela ISSI do
// patrimônio informado, portanto o patrimônio (mv_par03) é obrigatório.
If mv_par01 == 3 .and. Empty(mv_par03)
    MsgInfo("Para trocar os acessórios é necessário informar o patrimônio.", "Atenção")
    Return
EndIf

If !Empty(mv_par03)
    // aDoc[1] - ZI_DOC
    // aDoc[2] - ZI_STATUS
    // aDoc[3] - ZI_ISSI
    // aDoc[4] - ZI_NUMSEQ
    aDoc := U_RetDocPat(AllTrim(mv_par03))

    If Empty(aDoc[1])
        MsgInfo('Nenhum movimento ativo foi encontrado para esse Patrimônio.', "Atenção")
        Return
    EndIf

    SZH->(DbSeek(xFilial("SZH") + aDoc[1]))
EndIf

If SZH->ZH_STATUS == "D"
    MsgInfo('Esse patrimônio já foi devolvido, portanto, não pode ser substituído.', "Atenção")
    Return
EndIf

cCodPost   := SZH->ZH_CODPOST
cLocalid   := SZH->ZH_LOCALID
cDocumento := SZH->ZH_DOC
cCCusto    := SZH->ZH_CC
cResp      := SZH->ZH_CODRESP
cMotivo    := SZH->ZH_MOTIVO
cNumSeq    := If(Empty(mv_par03), Posicione("SZI", 1, xFilial("SZI") + cCodPost + cLocalid + cDocumento, "ZI_NUMSEQ"), aDoc[4])
cISSI      := If(Empty(mv_par03), Posicione("SZI", 1, xFilial("SZI") + cCodPost + cLocalid + cDocumento, "ZI_ISSI"), aDoc[3])

// Sem a ISSI do patrimônio não há como filtrar os acessórios da substituição.
If mv_par01 == 3 .and. Empty(cISSI)
    MsgInfo("Não foi possível identificar a ISSI do patrimônio informado.", "Atenção")
    Return
EndIf

FWExecView("", "MOVSUBS", MODEL_OPERATION_UPDATE, , { || .T. })

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
Local oSZIOri  := FWFormStruct(1, "SZI")
Local oSZISub  := FWFormStruct(1, "SZI")
Local cFilOri  := ""
Local cFilSub  := ""

oModel := MPFormModel():New("MOVSUBSM", /*bPre*/, {|oModel| MovTudoOk(oModel)}, { |oMdl| AtuaMov(oMdl) }, /*bCancel*/)

oStruSZH:SetProperty("ZH_DOC", MODEL_FIELD_WHEN, FwBuildFeature(STRUCT_FEATURE_WHEN, ".F."))
oStruSZH:SetProperty("ZH_EMISSAO", MODEL_FIELD_WHEN, FwBuildFeature(STRUCT_FEATURE_WHEN, ".F."))
oStruSZH:SetProperty("ZH_CODPOST", MODEL_FIELD_WHEN, FwBuildFeature(STRUCT_FEATURE_WHEN, ".F."))
oStruSZH:SetProperty("ZH_LOCALID", MODEL_FIELD_WHEN, FwBuildFeature(STRUCT_FEATURE_WHEN, ".F."))
oStruSZH:SetProperty("ZH_CC", MODEL_FIELD_WHEN, FwBuildFeature(STRUCT_FEATURE_WHEN, ".F."))
oStruSZH:SetProperty("ZH_CODRESP", MODEL_FIELD_WHEN, FwBuildFeature(STRUCT_FEATURE_WHEN, ".F."))

oSZISub:SetProperty('ZI_DTBASE', MODEL_FIELD_INIT , {|| dDataBase})

oModel:AddFields("SZHMASTER",, oStruSZH)

oModel:AddGrid("SZIORIGEM", "SZHMASTER", oSZIOri)
oModel:AddGrid("SZISUBST", "SZHMASTER", oSZISub)

// Troca de acessorios / mv_par01 == 3)
// O SetRelation original do SZIORIGEM amarra ZI_CODPOST + ZI_LOCALID + ZI_DOC ao
// cabecalho SZHMASTER. Com o documento fixado na relacao, o SetLoadFilter por
// ZI_ISSI so consegue enxergar o que esta gravado NAQUELE ZI_DOC; o acessorio da
// mesma ISSI gravado em outro documento nunca era alcancado e o grid de origem
// vinha vazio mesmo com a ISSI correta. Por isso, em mv_par01 == 3, a relacao
// deixa de fixar o documento e a selecao do conjunto fica por conta do filtro.
If mv_par01 == 3
    // Acessorios: relaciona somente a filial; ZI_ISSI vem pelo SetLoadFilter.
    oModel:SetRelation("SZIORIGEM", {{"ZI_FILIAL", "xFilial('SZI')"}}, SZI->(IndexKey(1)))
Else
    oModel:SetRelation("SZIORIGEM", {{"ZI_FILIAL", "xFilial('SZI')"}, {"ZI_CODPOST", "ZH_CODPOST"}, {"ZI_LOCALID", "ZH_LOCALID"},;
                                     {"ZI_DOC", "ZH_DOC"}}, SZI->(IndexKey(1)))
EndIf

// Filtro do grid de origem: sempre traz apenas itens ativos (nao devolvidos),
// combinado com a regra de patrimonio conforme o tipo de substituicao (mv_par01).
cFilOri := "ZI_STATUS = 'A'"

If mv_par01 == 2
    cFilOri += " AND ZI_PATRIM <> ''"
ElseIf mv_par01 == 3
    cFilOri += " AND ZI_PATRIM = ''"

    // Substituicao de acessorios: mostra somente os acessorios da ISSI do
    // patrimonio informado no Pergunte.
    If !Empty(cISSI)
        cFilOri += " AND ZI_ISSI = '" + AllTrim(cISSI) + "'"
    EndIf
EndIf

oModel:GetModel("SZIORIGEM"):SetLoadFilter(Nil, cFilOri)

If mv_par01 == 3
    // Itens substitutos: apenas acessorios (sem patrimonio) e ativos.
    cFilSub := "ZI_STATUS = 'A' AND ZI_PATRIM = ''"

    // Mesma regra do grid de origem: so os acessorios da ISSI do patrimonio.
    If !Empty(cISSI)
        cFilSub += " AND ZI_ISSI = '" + AllTrim(cISSI) + "'"
    EndIf

    oModel:GetModel("SZISUBST"):SetLoadFilter(Nil, cFilSub)

    // Mesmo tratamento do grid de origem: sem fixar ZI_DOC, a lista de
    // substitutos enxerga todos os acessorios da ISSI, e nao so os do documento
    // do cabecalho. A selecao do conjunto fica por conta do SetLoadFilter.
    oModel:SetRelation("SZISUBST", {{"ZI_FILIAL", "xFilial('SZI')"}}, SZI->(IndexKey(1)))
EndIf

oModel:SetPrimaryKey({})

oModel:GetModel("SZIORIGEM"):SetOnlyView(.T.)

oModel:SetDescription("Substituição")
oModel:GetModel("SZHMASTER"):SetDescription("Dados do Documento")
oModel:GetModel("SZIORIGEM"):SetDescription("Dados dos Itens dos Documentos")
oModel:GetModel("SZISUBST"):SetDescription("Dados dos Itens Substitutos")

Return(oModel)

/*/{Protheus.doc} VIEWDEF
View do MVC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ViewDef()

Local oView
Local oStruSZH   := FWFormStruct(2, "SZH")
Local oSZIOri    := FWFormStruct(2, "SZI", {|x| !AllTrim(x) + "|" $ "ZI_CODPOST|ZI_LOCALID|ZI_DATADEV|ZI_PERDA|ZI_DPSMI|ZI_DPSEQ|ZI_DPSKIT|"+;
                                                                    "ZI_DPSSUB|ZI_DPSMC|ZI_DPSEQDV|ZI_DTBASE|"})
Local oSZISub    := FWFormStruct(2, "SZI", {|x| !AllTrim(x) + "|" $ "ZI_CODPOST|ZI_LOCALID|ZI_STATUS|ZI_DATADEV|ZI_PERDA|ZI_DOCSUBS|ZI_DPSMI|ZI_DPSEQ|"+;
                                                                    "ZI_DPSKIT|ZI_DPSSUB|ZI_DPSMC|ZI_DPSEQDV|ZI_DPSMG|ZI_DTBASE|"})
Local oModel     := FWLoadModel("MOVSUBS")

oView := FWFormView():New()

oView:SetModel(oModel)

oView:AddField("V_SZH", oStruSZH, "SZHMASTER")
oView:AddGrid("V_SZIORIG", oSZIOri, "SZIORIGEM")
oView:AddGrid("V_SZISUBS", oSZISub, "SZISUBST")

oView:SetCloseOnOk({|| .T.})

oView:CreateHorizontalBox("CABEC", 30)
oView:CreateHorizontalBox("ITEMORIG", 30)
oView:CreateHorizontalBox("TOOLBAR", 10)
oView:CreateHorizontalBox("ITEMSUBS", 30)

If mv_par01 < 3
    oView:AddOtherObject("BUTTONKIT", {|oPanel| ButtonKit(oPanel)})
    oView:SetOwnerView("BUTTONKIT", "TOOLBAR")
EndIf

oView:SetOwnerView("V_SZH", "CABEC")
oView:SetOwnerView("V_SZIORIG", "ITEMORIG")
oView:SetOwnerView("V_SZISUBS", "ITEMSUBS")

oView:SetViewCanActivate({|| ValidaSubs()})

Return(oview)

/*/{Protheus.doc} ButtonKit
Botão para disparo do Kit.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ButtonKit(oPanel)

Local oBtn
Local oBtnEst

If mv_par01 == 1
    oBtn    := TButton():New(10, 010, "+ Kit", oPanel, {|| MsvPodeAdd() .and. PesqKit()}, 80, 20,,,,.T.)
    oBtnEst := TButton():New(10, 095, "Estornar", oPanel, {|| MsvEstorna()}, 80, 20,,,,.T.)
ElseIf mv_par01 == 2
    oBtn    := TButton():New(10, 010, "+ Patrimônio", oPanel, {|| MsvPodeAdd() .and. LoadNewPat()}, 120, 20,,,,.T.)
    oBtnEst := TButton():New(10, 135, "Estornar", oPanel, {|| MsvEstorna()}, 80, 20,,,,.T.)
EndIf

Return

/*/{Protheus.doc} MsvEstorna
Abre a seleção dos agrupamentos de substituição ativos para estornar a amarração
entre o patrimônio original e o kit / patrimônio substituto.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function MsvEstorna()

Local oSay1
Local oCbxEst
Local oButton1, oButton2
Local oDlg
Local nX       := 0
Local aRefAtiv := MsvRefAtiv()
Local aCbxEst  := {}
Local cEscolha := ""

If Len(aRefAtiv) == 0
    Help(,, "SEMEST",, "Não há amarração de patrimônio substituído para estornar.", 1, 0)
    Return
EndIf

For nX := 1 to Len(aRefAtiv)
    AAdd(aCbxEst, aRefAtiv[nX][1])
Next nX

DEFINE MSDIALOG oDlg TITLE "Estorno da Substituição" FROM 000, 000 TO 130, 500 COLORS 0, 16777215 PIXEL

@ 008, 005 SAY oSay1 PROMPT "Patrim. Substituído" SIZE 060, 007 OF oDlg COLORS 0, 16777215 PIXEL
oCbxEst := TComboBox():New(018, 005, {|u| cEscolha := MsvSetOri(cEscolha, u)}, aCbxEst, 237, 010, oDlg,,,,,, .T.,,,,,,,, "cEscolha")

@ 042, 163 BUTTON oButton1 PROMPT "Confirmar" ACTION(MsvConfEst(cEscolha, aRefAtiv, oDlg)) SIZE 037, 012 OF oDlg PIXEL
@ 042, 205 BUTTON oButton2 PROMPT "Cancelar" ACTION(cEscolha := "", oDlg:End()) SIZE 037, 012 OF oDlg PIXEL

ACTIVATE MSDIALOG oDlg CENTERED

Return

/*/{Protheus.doc} MsvConfEst
Confirma o estorno da amarração escolhida: apaga do grid SZISUBST as linhas do
agrupamento e libera novamente o patrimônio original em MsvOpcOri().

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12

@param cEscolha, character, Descrição escolhida no combo.
@param aRefAtiv, array, Agrupamentos ativos devolvidos por MsvRefAtiv().
@param oDlg, object, Diálogo de estorno.

@return nil
/*/
Static Function MsvConfEst(cEscolha, aRefAtiv, oDlg)

Local nX     := 0
Local nPos   := 0
Local cGrupo := ""
Local cMsg   := ""

Default cEscolha := ""
Default aRefAtiv := {}

If Empty(cEscolha)
    Help(,, "SEMEST",, "Selecione a amarração de patrimônio substituído que será estornada.", 1, 0)
    Return
EndIf

nPos := aScan(aRefAtiv, {|x| AllTrim(x[1]) == AllTrim(cEscolha)})

If nPos == 0
    Help(,, "SEMEST",, "Selecione a amarração de patrimônio substituído que será estornada.", 1, 0)
    Return
EndIf

cMsg := "Confirma o estorno da substituição do patrimônio [" + AllTrim(aRefAtiv[nPos][4]) +;
        " | ISSI " + AllTrim(aRefAtiv[nPos][5]) + "]?" + Chr(13) + Chr(10) +;
        "Serão excluída(s) " + AllTrim(Str(aRefAtiv[nPos][6])) + " linha(s) de itens substitutos."

If !MsgYesNo(cMsg, "Estorno da Substituição")
    Return
EndIf

cGrupo := aRefAtiv[nPos][2]

MsvDelGrup(cGrupo)

// Garante que não sobre referência residual do agrupamento estornado, para que
// o patrimônio original volte a ser listado em MsvOpcOri().
For nX := Len(aRefSubs) to 1 Step -1
    If AllTrim(aRefSubs[nX][5]) == AllTrim(cGrupo)
        aDel(aRefSubs, nX)
        aSize(aRefSubs, Len(aRefSubs) - 1)
    EndIf
Next nX

oDlg:End()

Return

/*/{Protheus.doc} MsvPodeAdd
Verifica se ainda é possível incluir substitutos para o documento original.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function MsvPodeAdd()

Local aPatOri := MsvPatOri()
Local lRet    := .T.

// MsvQtdRef() conta apenas ISSIs com referência ativa (MsvIssUsa despreza linha
// deletada / referência órfã), portanto após um estorno a contagem cai e a
// inclusão de um novo kit / patrimônio volta a ser permitida.
If MsvQtdRef() >= Len(aPatOri)
    Help(,, "MAXKIT",, "O documento original tem apenas " + AllTrim(Str(Len(aPatOri))) +;
        " patrimônio(s) ativo(s); não é possível incluir mais kits.", 1, 0)
    lRet := .F.
EndIf

Return(lRet)

/*/{Protheus.doc} MsvOpcOri
Monta a lista de patrimônios de origem ainda disponíveis para referência.

aRet[n][1] - Descrição para o combo (ZI_PATRIM | ISSI | ZI_PRODUTO)
aRet[n][2] - ZI_ITEM
aRet[n][3] - ZI_PATRIM
aRet[n][4] - ZI_ISSI
aRet[n][5] - ZI_CODKIT
aRet[n][6] - ZI_LOCALIZ
aRet[n][7] - ZI_DOC (documento de origem do item)

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function MsvOpcOri()

Local nX      := 0
Local aPatOri := MsvPatOri()
Local aRet    := {}

For nX := 1 to Len(aPatOri)
    // Oculta os patrimônios de origem que já foram referenciados.
    If MsvIssUsa(aPatOri[nX][3])
        Loop
    EndIf

    AAdd(aRet, {AllTrim(aPatOri[nX][2]) + " | ISSI " + AllTrim(aPatOri[nX][3]) + " | " + AllTrim(aPatOri[nX][4]),;
                aPatOri[nX][1],;
                aPatOri[nX][2],;
                aPatOri[nX][3],;
                aPatOri[nX][5],;
                aPatOri[nX][7],;
                aPatOri[nX][8]})
Next nX

Return(aRet)

/*/{Protheus.doc} MsvAddRef
Registra a referência da linha substituta com o patrimônio original.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function MsvAddRef(nLinha, cItemOri, cPatOri, cIssiOri, cGrupo, lAncora, cDocOri)

Local nPos := aScan(aRefSubs, {|x| x[1] == nLinha})

Default cGrupo  := ""
Default lAncora := .T.
// Sem documento informado vale o documento do cabeçalho (comportamento antigo).
Default cDocOri := cDocumento

If nPos > 0
    aRefSubs[nPos][2] := cItemOri
    aRefSubs[nPos][3] := cPatOri
    aRefSubs[nPos][4] := cIssiOri
    aRefSubs[nPos][5] := cGrupo
    aRefSubs[nPos][6] := lAncora
    aRefSubs[nPos][7] := cDocOri
Else
    AAdd(aRefSubs, {nLinha, cItemOri, cPatOri, cIssiOri, cGrupo, lAncora, cDocOri})
EndIf

Return

/*/{Protheus.doc} MsvDelRef
Remove a referência da linha substituta apagada do grid.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function MsvDelRef(nLinha)

Local nPos := aScan(aRefSubs, {|x| x[1] == nLinha})

If nPos > 0
    aDel(aRefSubs, nPos)
    aSize(aRefSubs, Len(aRefSubs) - 1)
EndIf

Return

/*/{Protheus.doc} MsvRefLin
Devolve a posição em aRefSubs da referência ATIVA da linha informada do grid
SZISUBST.

Uma referência só é ativa quando a linha ainda existe no grid e não está
deletada; assim, uma amarração estornada (linha apagada ou índice órfão) deixa
de ser considerada na validação de duplicidade e na baixa do documento original.
Quando houver mais de uma entrada para a mesma linha (estorno seguido de nova
amarração no mesmo patrimônio), prevalece a última gravada.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12

@param nLinha, numeric, Linha do grid SZISUBST.

@return numeric, Posição em aRefSubs; 0 quando não há referência ativa.
/*/
Static Function MsvRefLin(nLinha)

Local nX     := 0
Local nRet   := 0
Local oModel := FWModelActive()
Local oGrid  := Nil

Default nLinha := 0

If nLinha < 1 .or. Len(aRefSubs) == 0
    Return(0)
EndIf

If oModel <> Nil
    oGrid := oModel:GetModel("SZISUBST")
EndIf

If oGrid <> Nil
    // Linha que não existe mais no grid não tem amarração vigente.
    If nLinha > oGrid:Length()
        Return(0)
    EndIf

    // Linha apagada (estornada) não tem amarração vigente.
    If oGrid:IsDeleted(nLinha)
        Return(0)
    EndIf
EndIf

For nX := 1 to Len(aRefSubs)
    If aRefSubs[nX][1] == nLinha
        nRet := nX
    EndIf
Next nX

Return(nRet)

/*/{Protheus.doc} MsvChvLin
Monta a chave de identificação da linha substituta do grid SZISUBST.

A chave (ZI_ITEM + ZI_CODKIT + ZI_PATRIM) é usada para reposicionar as
referências de aRefSubs depois que o grid reindexa as linhas novas.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12

@param oGrid, object, Grid dos itens substitutos (SZISUBST).
@param oModel, object, Modelo de dados ativo.
@param nLinha, numeric, Linha do grid.

@return character, Chave da linha; "" quando a linha não existe.
/*/
Static Function MsvChvLin(oGrid, oModel, nLinha)

Local cRet := ""

If oGrid == Nil .or. nLinha < 1 .or. nLinha > oGrid:Length()
    Return("")
EndIf

// ZI_DOC entra na chave: com as linhas de origem vindas de documentos
// distintos (troca de acessorios pela ISSI), ZI_ITEM + ZI_CODKIT + ZI_PATRIM
// pode colidir entre dois documentos diferentes.
cRet := AllTrim(oGrid:GetValue("ZI_DOC", nLinha, oModel)) + "|" +;
        AllTrim(oGrid:GetValue("ZI_ITEM", nLinha, oModel)) + "|" +;
        AllTrim(oGrid:GetValue("ZI_CODKIT", nLinha, oModel)) + "|" +;
        AllTrim(oGrid:GetValue("ZI_PATRIM", nLinha, oModel))

Return(cRet)

/*/{Protheus.doc} MsvRefAtiv
Devolve os agrupamentos de substituição ainda ativos (linhas existentes no grid
SZISUBST e não deletadas), para permitir o estorno da amarração.

aRet[n][1] - Descrição para o combo (ZI_PATRIM origem | ISSI origem | Kit/Produto)
aRet[n][2] - Agrupador (aRefSubs[n][5])
aRet[n][3] - ZI_ITEM do item de origem
aRet[n][4] - ZI_PATRIM do patrimônio de origem
aRet[n][5] - ZI_ISSI do patrimônio de origem
aRet[n][6] - Quantidade de linhas do agrupamento

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12

@return array, Agrupamentos ativos.
/*/
Static Function MsvRefAtiv()

Local nX      := 0
Local nPos    := 0
Local nLinha  := 0
Local cGrupo  := ""
Local cKitPrd := ""
Local cDescri := ""
Local oModel  := FWModelActive()
Local oGrid   := Nil
Local aRet    := {}

If oModel <> Nil
    oGrid := oModel:GetModel("SZISUBST")
EndIf

If oGrid == Nil .or. Len(aRefSubs) == 0
    Return(aRet)
EndIf

For nX := 1 to Len(aRefSubs)
    nLinha := aRefSubs[nX][1]

    // Só entra agrupamento cuja linha ainda existe no grid.
    If nLinha < 1 .or. nLinha > oGrid:Length()
        Loop
    EndIf

    // Linha apagada no grid não é referência ativa.
    If oGrid:IsDeleted(nLinha)
        Loop
    EndIf

    cGrupo := aRefSubs[nX][5]

    // Descrição pelo kit; acessório avulso sem kit usa o produto.
    cKitPrd := AllTrim(oGrid:GetValue("ZI_CODKIT", nLinha, oModel))

    If Empty(cKitPrd)
        cKitPrd := AllTrim(oGrid:GetValue("ZI_PRODUTO", nLinha, oModel))
    EndIf

    cDescri := AllTrim(aRefSubs[nX][3]) + " | ISSI " + AllTrim(aRefSubs[nX][4]) + " | " + cKitPrd

    nPos := aScan(aRet, {|x| AllTrim(x[2]) == AllTrim(cGrupo)})

    If nPos > 0
        aRet[nPos][6] += 1

        // A âncora (item pai) é quem define a descrição do agrupamento.
        If aRefSubs[nX][6]
            aRet[nPos][1] := cDescri
            aRet[nPos][3] := aRefSubs[nX][2]
            aRet[nPos][4] := aRefSubs[nX][3]
            aRet[nPos][5] := aRefSubs[nX][4]
        EndIf

        Loop
    EndIf

    AAdd(aRet, {cDescri         ,;
                cGrupo          ,;
                aRefSubs[nX][2] ,;
                aRefSubs[nX][3] ,;
                aRefSubs[nX][4] ,;
                1})
Next nX

Return(aRet)

/*/{Protheus.doc} MsvLinGrup
Retorna as linhas do grid SZISUBST que pertencem ao agrupador informado,
ignorando as linhas já deletadas.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12

@param cGrupo, character, Agrupador do kit / patrimônio substituto.

@return array, Índices das linhas do grid, em ordem crescente.
/*/
Static Function MsvLinGrup(cGrupo)

Local nX     := 0
Local nLinha := 0
Local oModel := FWModelActive()
Local oGrid  := Nil
Local aRet   := {}

Default cGrupo := ""

If oModel <> Nil
    oGrid := oModel:GetModel("SZISUBST")
EndIf

If oGrid == Nil .or. Empty(cGrupo) .or. Len(aRefSubs) == 0
    Return(aRet)
EndIf

For nX := 1 to Len(aRefSubs)
    If AllTrim(aRefSubs[nX][5]) <> AllTrim(cGrupo)
        Loop
    EndIf

    nLinha := aRefSubs[nX][1]

    If nLinha < 1 .or. nLinha > oGrid:Length()
        Loop
    EndIf

    If oGrid:IsDeleted(nLinha)
        Loop
    EndIf

    If aScan(aRet, {|x| x == nLinha}) == 0
        AAdd(aRet, nLinha)
    EndIf
Next nX

ASort(aRet,,, {|x, y| x < y})

Return(aRet)

/*/{Protheus.doc} MsvDelGrup
Estorna a amarração do agrupamento informado: apaga do grid SZISUBST todas as
linhas substitutas do agrupamento e remove as referências de aRefSubs, liberando
novamente o patrimônio original para nova substituição.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12

@param cGrupo, character, Agrupador do kit / patrimônio substituto.

@return logical, .T. quando alguma linha foi apagada.
/*/
Static Function MsvDelGrup(cGrupo)

Local nX      := 0
Local nLinha  := 0
Local oView   := FWViewActive()
Local oModel  := FWModelActive()
Local oGrid   := Nil
Local aLinhas := {}
Local aChaves := {}
Local lRet    := .F.

Default cGrupo := ""

If oModel <> Nil
    oGrid := oModel:GetModel("SZISUBST")
EndIf

If oGrid == Nil .or. Empty(cGrupo)
    Return(.F.)
EndIf

aLinhas := MsvLinGrup(cGrupo)

If Len(aLinhas) == 0
    Return(.F.)
EndIf

// Fotografa a chave das linhas antes do DeleteLine(): as linhas novas são
// reindexadas pelo grid e as referências restantes precisam ser reposicionadas.
For nX := 1 to oGrid:Length()
    If oGrid:IsDeleted(nX)
        Loop
    EndIf

    AAdd(aChaves, {nX, MsvChvLin(oGrid, oModel, nX)})
Next nX

// Da maior para a menor linha, evitando reindexar o que ainda falta apagar.
For nX := Len(aLinhas) to 1 Step -1
    nLinha := aLinhas[nX]

    If nLinha < 1 .or. nLinha > oGrid:Length()
        Loop
    EndIf

    oGrid:GoLine(nLinha)
    oGrid:DeleteLine()

    // Remove a referência da linha estornada.
    MsvDelRef(nLinha)

    lRet := .T.
Next nX

// Reposiciona as referências que sobraram após a reindexação do grid.
MsvSincRef(aChaves)

If oGrid:Length() > 0
    oGrid:GoLine(1)
EndIf

If oView <> Nil
    oView:Refresh()
EndIf

Return(lRet)

/*/{Protheus.doc} MsvSincRef
Reposiciona aRefSubs[n][1] pela chave da linha substituta
(ZI_ITEM + ZI_CODKIT + ZI_PATRIM), varrendo o grid SZISUBST, e descarta as
entradas cuja linha não existe mais.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12

@param aChaves, array, Opcional. Fotografia {nLinha, cChave} tirada antes do
       DeleteLine(); quando omitida, a chave é lida da linha apontada hoje.

@return nil
/*/
Static Function MsvSincRef(aChaves)

Local nX     := 0
Local nY     := 0
Local nPos   := 0
Local nLinha := 0
Local cChave := ""
Local oModel := FWModelActive()
Local oGrid  := Nil
Local aTira  := {}

Default aChaves := {}

If oModel <> Nil
    oGrid := oModel:GetModel("SZISUBST")
EndIf

If oGrid == Nil .or. Len(aRefSubs) == 0
    Return
EndIf

For nX := 1 to Len(aRefSubs)
    cChave := ""
    nLinha := 0

    // A chave fotografada antes da exclusão tem prioridade.
    nPos := aScan(aChaves, {|x| x[1] == aRefSubs[nX][1]})

    If nPos > 0
        cChave := aChaves[nPos][2]
    Else
        cChave := MsvChvLin(oGrid, oModel, aRefSubs[nX][1])
    EndIf

    If !Empty(cChave)
        For nY := 1 to oGrid:Length()
            If oGrid:IsDeleted(nY)
                Loop
            EndIf

            If MsvChvLin(oGrid, oModel, nY) == cChave
                nLinha := nY
                Exit
            EndIf
        Next nY
    EndIf

    If nLinha == 0
        // A linha referenciada não existe mais no grid.
        AAdd(aTira, nX)
    Else
        aRefSubs[nX][1] := nLinha
    EndIf
Next nX

// Descarta de trás para frente para não bagunçar os índices de aRefSubs.
For nX := Len(aTira) to 1 Step -1
    aDel(aRefSubs, aTira[nX])
    aSize(aRefSubs, Len(aRefSubs) - 1)
Next nX

Return

/*/{Protheus.doc} ValidaSubs
Valida se há itens ativos para a substituição.

Kit (mv_par01 == 1) e patrimônio (mv_par01 == 2) continuam validando os itens do
documento original (Cód.Posto + Localidade + Documento).

Acessórios (mv_par01 == 3) são validados pela ISSI do patrimônio informado no
Pergunte, e não pelo documento: basta existir acessório ativo (ZI_PATRIM vazio)
com a mesma ISSI, esteja ele em qual documento estiver.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12

@return logical, .T. quando há item ativo para substituir.
/*/
Static Function ValidaSubs()

Local aArea   := GetArea()
Local aAreaZI := SZI->(GetArea())
Local nOrdZI  := SZI->(IndexOrd())
Local lRet    := .F.

If mv_par01 == 3
    // Acessórios: a validação é pela ISSI do patrimônio informado.
    lRet := MsvValAces()
Else
    lRet := MsvValDoc()
EndIf

// Devolve a SZI para a ordem / posição de quem chamou.
SZI->(DbSetOrder(nOrdZI))

RestArea(aAreaZI)
RestArea(aArea)

If !lRet
    If mv_par01 == 3
        Help(,, "SEMIT",, "Não há acessórios ativos para a ISSI " + AllTrim(cISSI) +;
            " do patrimônio informado.", 1, 0)
    Else
        Help(,, "SEMIT",, "Esse documento não tem nenhum item ativo para ser substituído", 1, 0)
    EndIf
EndIf

Return(lRet)

/*/{Protheus.doc} MsvValDoc
Valida os itens ativos do documento original (substituição de kit e de
patrimônio).

Mantém a varredura por Cód.Posto + Localidade + Documento; em mv_par01 == 2 só
conta item com patrimônio.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12

@return logical, .T. quando há item ativo no documento.
/*/
Static Function MsvValDoc()

Local lRet := .F.

SZI->(DbSetOrder(1)) // Cód.Posto + Localidade + Documento + Item

SZI->(DbSeek(xFilial("SZI") + cCodPost + cLocalid + cDocumento))
While SZI->ZI_FILIAL == xFilial("SZI") .and.;
    SZI->ZI_CODPOST == cCodPost .and.;
    SZI->ZI_LOCALID == cLocalid .and.;
    SZI->ZI_DOC == cDocumento .and. !SZI->(EOF())

    If SZI->ZI_STATUS <> "A"
        SZI->(DbSkip())
        Loop
    EndIf

    If mv_par01 == 2
        If Empty(SZI->ZI_PATRIM)
            SZI->(DbSkip())
            Loop
        EndIf
    EndIf

    lRet := .T.
    Exit
End

Return(lRet)

/*/{Protheus.doc} MsvValAces
Valida se existe acessório ativo para a ISSI do patrimônio informado.

Varre a SZI pela ordem 5 (ISSI + Documento + Item), sem amarrar Cód.Posto,
Localidade nem Documento: aceita o primeiro item com ZI_STATUS == "A",
ZI_PATRIM vazio e a mesma ISSI.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12

@return logical, .T. quando há acessório ativo para a ISSI.
/*/
Static Function MsvValAces()

Local lRet := .F.

If Empty(cISSI)
    Return(.F.)
EndIf

SZI->(DbSetOrder(5)) // ISSI + Documento + Item

SZI->(DbSeek(xFilial("SZI") + cISSI))
While SZI->ZI_FILIAL == xFilial("SZI") .and.;
    AllTrim(SZI->ZI_ISSI) == AllTrim(cISSI) .and. !SZI->(EOF())

    If SZI->ZI_STATUS <> "A"
        SZI->(DbSkip())
        Loop
    EndIf

    If !Empty(SZI->ZI_PATRIM)
        SZI->(DbSkip())
        Loop
    EndIf

    lRet := .T.
    Exit
End

Return(lRet)

/*/{Protheus.doc} MsvPatOri
Retorna os patrimônios ativos do documento original.

aRet[n][1] - ZI_ITEM
aRet[n][2] - ZI_PATRIM
aRet[n][3] - ZI_ISSI
aRet[n][4] - ZI_PRODUTO
aRet[n][5] - ZI_CODKIT
aRet[n][6] - ZI_DESCRI
aRet[n][7] - ZI_LOCALIZ
aRet[n][8] - ZI_DOC (documento de origem do item)

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function MsvPatOri()

Local aArea := GetArea()
Local aAreaZI := SZI->(GetArea())
Local aRet  := {}

SZI->(DbSetOrder(1)) // Cód.Posto + Localidade + Documento + Item

If SZI->(DbSeek(xFilial("SZI") + cCodPost + cLocalid + cDocumento))
    While SZI->ZI_FILIAL == xFilial("SZI") .and.;
        SZI->ZI_CODPOST == cCodPost .and.;
        SZI->ZI_LOCALID == cLocalid .and.;
        SZI->ZI_DOC == cDocumento .and. !SZI->(EOF())

        If SZI->ZI_STATUS $ "A" .and. !Empty(SZI->ZI_PATRIM)
            AAdd(aRet, {SZI->ZI_ITEM   ,;
                        SZI->ZI_PATRIM ,;
                        SZI->ZI_ISSI   ,;
                        SZI->ZI_PRODUTO,;
                        SZI->ZI_CODKIT ,;
                        SZI->ZI_DESCRI ,;
                        SZI->ZI_LOCALIZ,;
                        SZI->ZI_DOC})
        EndIf

        SZI->(DbSkip())
    End
EndIf

RestArea(aAreaZI)
RestArea(aArea)

Return(aRet)

/*/{Protheus.doc} MsvAcsIss
Devolve os acessórios ativos (ZI_PATRIM vazio) da ISSI do patrimônio informado,
independente do documento em que estejam gravados.

aRet[n][1] - ZI_DOC
aRet[n][2] - ZI_ITEM
aRet[n][3] - ZI_PRODUTO
aRet[n][4] - ZI_CODPOST
aRet[n][5] - ZI_LOCALID
aRet[n][6] - ZI_CODKIT

Substitui a varredura antiga por Cód.Posto + Localidade + Documento (MsvAcsOri),
que só enxergava o acessório gravado no documento do cabeçalho.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12

@return array, Acessórios ativos da ISSI.
/*/
Static Function MsvAcsIss()

Local aArea   := GetArea()
Local aAreaZI := SZI->(GetArea())
Local nOrdZI  := SZI->(IndexOrd())
Local cIssiPt := MsvIssPat()
Local aRet    := {}

If Empty(cIssiPt)
    SZI->(DbSetOrder(nOrdZI))
    RestArea(aAreaZI)
    RestArea(aArea)
    Return(aRet)
EndIf

SZI->(DbSetOrder(5)) // ISSI + Documento + Item

If SZI->(DbSeek(xFilial("SZI") + cIssiPt))
    While SZI->ZI_FILIAL == xFilial("SZI") .and.;
        AllTrim(SZI->ZI_ISSI) == cIssiPt .and. !SZI->(EOF())

        If SZI->ZI_STATUS == "A" .and. Empty(SZI->ZI_PATRIM)
            AAdd(aRet, {SZI->ZI_DOC    ,;
                        SZI->ZI_ITEM   ,;
                        SZI->ZI_PRODUTO,;
                        SZI->ZI_CODPOST,;
                        SZI->ZI_LOCALID,;
                        SZI->ZI_CODKIT})
        EndIf

        SZI->(DbSkip())
    End
EndIf

SZI->(DbSetOrder(nOrdZI))

RestArea(aAreaZI)
RestArea(aArea)

Return(aRet)

/*/{Protheus.doc} MsvIssUsa
Informa se a ISSI do patrimônio original já foi referenciada.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function MsvIssUsa(cIssi)

Local nX     := 0
Local oModel := FWModelActive()
Local oGrid  := Nil
Local lRet   := .F.

If Empty(cIssi) .or. Len(aRefSubs) == 0
    Return(.F.)
EndIf

If oModel <> Nil
    oGrid := oModel:GetModel("SZISUBST")
EndIf

For nX := 1 to Len(aRefSubs)
    If AllTrim(aRefSubs[nX][4]) <> AllTrim(cIssi)
        Loop
    EndIf

    // Linha inexistente (referência órfã de um estorno) ou apagada no grid não
    // conta como referência ativa; caso contrário a ISSI de origem continuaria
    // "ocupada" depois do estorno.
    If oGrid <> Nil
        If aRefSubs[nX][1] < 1 .or. aRefSubs[nX][1] > oGrid:Length()
            Loop
        EndIf

        If oGrid:IsDeleted(aRefSubs[nX][1])
            Loop
        EndIf
    EndIf

    lRet := .T.
    Exit
Next nX

Return(lRet)

/*/{Protheus.doc} MsvQtdRef
Retorna quantas ISSIs de origem distintas já estão referenciadas.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function MsvQtdRef()

Local nX     := 0
Local aIssis := {}

For nX := 1 to Len(aRefSubs)
    If Empty(aRefSubs[nX][4])
        Loop
    EndIf

    If !MsvIssUsa(aRefSubs[nX][4])
        Loop
    EndIf

    If aScan(aIssis, {|x| AllTrim(x) == AllTrim(aRefSubs[nX][4])}) == 0
        AAdd(aIssis, aRefSubs[nX][4])
    EndIf
Next nX

Return(Len(aIssis))

/*/{Protheus.doc} ButtonKit
Pesquisa do Kit.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function PesqKit()

Local oSay1, oSay2, oSay3, oSay4
Local oGet1, oGet2, oGet3
Local oCbxOri
Local oButton1, oButton2
Local oDlg
Local oModel   := FWModelActive()
Local oGrid    := oModel:GetModel("SZIORIGEM")
Local aOpcOri  := MsvOpcOri()
Local aCbxOri  := {}
Local nX       := 0
Local cKit     := Space(6)
Local cISSI    := If(mv_par01 == 3, AllTrim(oGrid:GetValue("ZI_ISSI", 1, oModel)), Space(14))
Local cLocaliz := oGrid:GetValue("ZI_LOCALIZ", 1, oModel)
Local cOrigem  := ""

If Len(aOpcOri) == 0
    Help(,, "MAXKIT",, "O documento original tem apenas " + AllTrim(Str(Len(MsvPatOri()))) +;
        " patrimônio(s) ativo(s); não é possível incluir mais kits.", 1, 0)
    Return
EndIf

For nX := 1 to Len(aOpcOri)
    AAdd(aCbxOri, aOpcOri[nX][1])
Next nX

cOrigem := ""

DEFINE MSDIALOG oDlg TITLE "Pesquisa de Kits" FROM 000, 000  TO 260, 500 COLORS 0, 16777215 PIXEL

@ 005, 005 SAY oSay1 PROMPT "Kit" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
@ 014, 005 MSGET oGet1 VAR cKit VALID(cISSI := If(mv_par01 == 3, AllTrim(oGrid:GetValue("ZI_ISSI", 1, oModel)), Space(14))) SIZE 060, 010 OF oDlg COLORS 0, 16777215 F3 "Z20" PIXEL
@ 030, 005 SAY oSay2 PROMPT "ISSI" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
@ 056, 005 SAY oSay3 PROMPT "Localização" SIZE 035, 007 OF oDlg COLORS 0, 16777215 PIXEL
@ 039, 005 MSGET oGet2 VAR cISSI SIZE 060, 010 OF oDlg COLORS 0, 16777215 PIXEL
@ 065, 005 MSGET oGet3 VAR cLocaliz SIZE 237, 010 OF oDlg COLORS 0, 16777215 PIXEL

@ 082, 005 SAY oSay4 PROMPT "Patrim. Substituído" SIZE 060, 007 OF oDlg COLORS 0, 16777215 PIXEL
oCbxOri := TComboBox():New(091, 005, {|u| cOrigem := MsvSetOri(cOrigem, u)}, aCbxOri, 237, 010, oDlg,,,,,, .T.,,,,,,,, "cOrigem")

@ 114, 163 BUTTON oButton1 PROMPT "Confirmar" ACTION(MsvConfKit(cKit, cISSI, cLocaliz, cOrigem, aOpcOri, oDlg)) SIZE 037, 012 OF oDlg PIXEL
@ 114, 205 BUTTON oButton2 PROMPT "Cancelar" ACTION(oDlg:End()) SIZE 037, 012 OF oDlg PIXEL

ACTIVATE MSDIALOG oDlg CENTERED

Return

/*/{Protheus.doc} MsvConfKit
Confirma a inclusão do kit exigindo o patrimônio de origem.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function MsvConfKit(cKit, cISSI, cLocaliz, cOrigem, aOpcOri, oDlg)

Local nPos := 0

If Empty(cOrigem)
    Help(,, "SEMPATORI",, "Selecione o patrimônio substituído antes de confirmar.", 1, 0)
    Return
EndIf

nPos := aScan(aOpcOri, {|x| AllTrim(x[1]) == AllTrim(cOrigem)})

If nPos == 0
    Help(,, "SEMPATORI",, "Selecione o patrimônio substituído antes de confirmar.", 1, 0)
    Return
EndIf

LoadKit(cKit, cISSI, cLocaliz, aOpcOri[nPos][3], aOpcOri[nPos][4], aOpcOri[nPos][2])

oDlg:End()

Return

/*/{Protheus.doc} ButtonKit
Carrega o kit substituto.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function LoadKit(cKit, cISSI, cLocaliz, cPatOrig, cIssiOrig, cItemOrig)

Local nX        := 0
Local cItem     := "000"
Local oView     := FWViewActive()
Local oModel    := FWModelActive()
Local oForm     := oModel:GetModel('SZHMASTER')
Local oGrid     := oModel:GetModel('SZISUBST')
Local cCodPost  := oForm:GetValue("ZH_CODPOST")
Local cLocalid  := oForm:GetValue("ZH_LOCALID")
Local cProduto  := ""
Local cNumSeq   := U_RetNumSeq()
Local lTemSaldo := .T.
Local nLinha    := 0
Local cGrupo    := ""
Local lAncKit   := .T.

Default cPatOrig  := ""
Default cIssiOrig := ""
Default cItemOrig := ""

// Agrupador unico das linhas geradas nesta chamada: todas as linhas do mesmo kit
// compartilham o mesmo patrimonio de origem sem caracterizar duplicidade.
nSeqGrup++
cGrupo  := "K" + StrZero(nSeqGrup, 6)
lAncKit := .T.

// A ISSI das linhas do kit substituto é sempre a ISSI do patrimônio original.
If !Empty(cIssiOrig) .and. mv_par01 == 3
    cISSI := cIssiOrig
EndIf

SB1->(DbSetOrder(1)) // Código
SZA->(DbSetOrder(1)) // Produto + Prod. similar
SZF->(DbSetOrder(1)) // Cod.posto + Localidade + Produto + Armazém
Z21->(DbSetOrder(1)) // Kit

If Z21->(DbSeek(xFilial("Z21") + cKit))
    While Z21->Z21_FILIAL == xFilial("Z21") .and.;
        Z21->Z21_CODIGO == cKit .and.;
        !Z21->(EOF())
		cProduto := Z21->Z21_CODSB1

		// Verifica se tem estoque para atender.
        lTemSaldo := .T.
		If SZF->(DbSeek(xFilial("SZF") + cCodPost + cLocalid + cProduto + "01"))
			If SZF->ZF_SALDO <= 0
				lTemSaldo := .F.
			EndIf
		Else
			lTemSaldo := .F.
		EndIf

		//Se não tiver estoque, busca produtos similares com saldo para atender.
		If !lTemSaldo
			SZA->(DbSeek(xFilial("SZA") + cProduto))
			While SZA->ZA_FILIAL == xFilial("SZA") .and.;
				SZA->ZA_PRODUTO == cProduto .and. !SZA->(EOF())
					If SZF->(DbSeek(xFilial("SZF") + cCodPost + cLocalid + SZA->ZA_PRODSIM + "01"))
						If SZF->ZF_SALDO > 0
							lTemSaldo := .T.
							cProduto  := SZA->ZA_PRODSIM
							Exit
						EndIf
					EndIf
				SZA->(DbSkip())
			End
		EndIf

		// Atualiza o número do item.
		If oGrid:Length() > 0
			For nX := 1 to oGrid:Length()
				oGrid:GoLine(nX)
				If oGrid:GetValue("ZI_ITEM") > cItem
					cItem := oGrid:GetValue("ZI_ITEM")
				EndIf
			Next nX
		EndIf

		SB1->(DbSeek(xFilial("SB1") + cProduto))

		lAddLine := .T.

		oGrid:AddLine()
		oGrid:GoLine(oGrid:Length())

		oGrid:SetValue("ZI_ITEM"   , Soma1(cItem))
		oGrid:SetValue("ZI_PRODUTO", cProduto)
		oGrid:SetValue("ZI_PATRIM" , Space(10))
		oGrid:SetValue("ZI_NUMSER" , Space(25))
		oGrid:SetValue("ZI_ISSI"   , cISSI)
		oGrid:SetValue("ZI_CODKIT" , cKit)
		oGrid:SetValue("ZI_QUANT"  , Z21->Z21_QTD)
		oGrid:SetValue("ZI_DATAMOV", dDataBase)
		oGrid:SetValue("ZI_LOCALIZ", cLocaliz)
		oGrid:SetValue("ZI_DESCRI", SB1->B1_DESC)
		oGrid:SetValue("ZI_NUMSEQ", cNumSeq)

		lAddLine := .F.

		nLinha := oGrid:Length()

		// Guarda a referência do patrimônio original desta linha substituta.
		// Somente a primeira linha (item pai) é a âncora do kit; as demais ficam
		// marcadas no mesmo agrupamento e não caracterizam duplicidade.
		MsvAddRef(nLinha, cItemOrig, cPatOrig, cIssiOrig, cGrupo, lAncKit)

		lAncKit := .F.

		If !lTemSaldo
			oGrid:DeleteLine()
			MsvDelRef(nLinha)
		EndIf

        Z21->(DbSkip())
    End

    oGrid:GoLine(1)

    If oView <> Nil
        oView:Refresh()
    EndIf
EndIf

Return

/*/{Protheus.doc} LoadNewPat
Seleciona o patrimônio substituto.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function LoadNewPat()

Local oView      := FWViewActive()
Local oModel     := FWModelActive()
Local oModelSZH  := oModel:GetModel("SZHMASTER")
Local oGrid      := oModel:GetModel("SZISUBST")
Local cCodPost   := oModelSZH:GetValue("ZH_CODPOST")
Local cLocalid   := oModelSZH:GetValue("ZH_LOCALID")
Local aOpcOri    := MsvOpcOri()
Local aOrigem    := {}
Local cKit       := ""
Local cISSI      := Space(14)
Local cLocaliz   := ""
Local cNumSeq    := U_RetNumSeq()
Local cProduto   := ""
Local cPatrim    := ""
Local cNumSer    := ""
Local cItem      := "001"
Local cPatOrig   := ""
Local cIssiOrig  := ""
Local cItemOrig  := ""
Local lTemSaldo  := .T.
Local nLinha     := 0

SB1->(DbSetOrder(1)) // Código
SZA->(DbSetOrder(1)) // Produto + Prod. similar
SZF->(DbSetOrder(1)) // Cod.posto + Localidade + Produto + Armazém

If Len(aOpcOri) == 0
    Help(,, "MAXKIT",, "O documento original tem apenas " + AllTrim(Str(Len(MsvPatOri()))) +;
        " patrimônio(s) ativo(s); não é possível incluir mais kits.", 1, 0)
    Return
EndIf

// Escolhe o patrimônio de origem que será substituído.
aOrigem := MsvSelOri(aOpcOri)

If Len(aOrigem) == 0
    Return
EndIf

cItemOrig := aOrigem[2]
cPatOrig  := aOrigem[3]
cIssiOrig := aOrigem[4]
cKit      := aOrigem[5]
cLocaliz  := aOrigem[6]

If ConPad1(,,, "SZJSUB")
    cItem    := "001"
    cProduto := SZJ->ZJ_PRODUTO
    cPatrim  := AllTrim(SZJ->ZJ_PATRIM)
    cNumSer  := AllTrim(SZJ->ZJ_NUMSER)

    // Verifica se tem estoque para atender.
    If SZF->(DbSeek(xFilial("SZF") + cCodPost + cLocalid + cProduto + "01"))
        If SZF->ZF_SALDO <= 0
            lTemSaldo := .F.
        EndIf
    Else
        lTemSaldo := .F.
    EndIf

    //Se não tiver estoque, busca produtos similares com saldo para atender.
    If !lTemSaldo
        SZA->(DbSeek(xFilial("SZA") + cProduto))
        While SZA->ZA_FILIAL == xFilial("SZA") .and.;
            SZA->ZA_PRODUTO == cProduto .and. !SZA->(EOF())
                If SZF->(DbSeek(xFilial("SZF") + cCodPost + cLocalid + SZA->ZA_PRODSIM + "01"))
                    If SZF->ZF_SALDO > 0
                        lTemSaldo := .T.
                        cProduto  := SZA->ZA_PRODSIM
                        Exit
                    EndIf
                EndIf
            SZA->(DbSkip())
        End
    EndIf

    SB1->(DbSeek(xFilial("SB1") + cProduto))

    lAddLine := .T.

    oGrid:AddLine()
    oGrid:GoLine(oGrid:Length())

    oGrid:SetValue("ZI_ITEM"   , cItem)
    oGrid:SetValue("ZI_PRODUTO", cProduto)
    oGrid:SetValue("ZI_PATRIM" , cPatrim)
    oGrid:SetValue("ZI_NUMSER" , cNumSer)
    oGrid:SetValue("ZI_ISSI"   , cISSI)
    oGrid:SetValue("ZI_CODKIT" , cKit)
    oGrid:SetValue("ZI_QUANT"  , 1)
    oGrid:SetValue("ZI_DATAMOV", dDataBase)
    oGrid:SetValue("ZI_LOCALIZ", cLocaliz)
    oGrid:SetValue("ZI_DESCRI", SB1->B1_DESC)
    oGrid:SetValue("ZI_NUMSEQ", cNumSeq)

    lAddLine := .F.

    nLinha := oGrid:Length()

    // Guarda a referência do patrimônio original desta linha substituta.
    // Patrimônio avulso: agrupamento próprio, sempre âncora.
    nSeqGrup++
    MsvAddRef(nLinha, cItemOrig, cPatOrig, cIssiOrig, "P" + StrZero(nSeqGrup, 6), .T.)

    If !lTemSaldo
        oGrid:DeleteLine()
        MsvDelRef(nLinha)
    EndIf

    oGrid:GoLine(1)

    If oView <> Nil
        oView:Refresh()
    EndIf
EndIf

Return

/*/{Protheus.doc} MsvSelOri
Seleciona o patrimônio de origem que será substituído.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function MsvSelOri(aOpcOri)

Local oSay1
Local oCbxOri
Local oButton1, oButton2
Local oDlg
Local aCbxOri := {}
Local aRet    := {}
Local nX      := 0
Local nPos    := 0
Local cOrigem := ""

For nX := 1 to Len(aOpcOri)
    AAdd(aCbxOri, aOpcOri[nX][1])
Next nX

DEFINE MSDIALOG oDlg TITLE "Patrimônio Substituído" FROM 000, 000 TO 130, 500 COLORS 0, 16777215 PIXEL

@ 008, 005 SAY oSay1 PROMPT "Patrim. Substituído" SIZE 060, 007 OF oDlg COLORS 0, 16777215 PIXEL
oCbxOri := TComboBox():New(018, 005, {|u| cOrigem := MsvSetOri(cOrigem, u)}, aCbxOri, 237, 010, oDlg,,,,,, .T.,,,,,,,, "cOrigem")

@ 042, 163 BUTTON oButton1 PROMPT "Confirmar" ACTION(MsvConfOri(cOrigem, oDlg)) SIZE 037, 012 OF oDlg PIXEL
@ 042, 205 BUTTON oButton2 PROMPT "Cancelar" ACTION(cOrigem := "", oDlg:End()) SIZE 037, 012 OF oDlg PIXEL

ACTIVATE MSDIALOG oDlg CENTERED

If !Empty(cOrigem)
    nPos := aScan(aOpcOri, {|x| AllTrim(x[1]) == AllTrim(cOrigem)})

    If nPos > 0
        aRet := aClone(aOpcOri[nPos])
    EndIf
EndIf

Return(aRet)

/*/{Protheus.doc} MsvConfOri
Confirma a escolha do patrimônio de origem na seleção do patrimônio novo.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function MsvConfOri(cOrigem, oDlg)

If Empty(cOrigem)
    Help(,, "SEMPATORI",, "Selecione o patrimônio substituído antes de confirmar.", 1, 0)
    Return
EndIf

oDlg:End()

Return

/*/{Protheus.doc} MsvSetOri
Bloco de leitura/gravação do combo de patrimônio de origem.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function MsvSetOri(cOrigem, xNovo)

Local cRet := cOrigem

If ValType(xNovo) == "C"
    cRet := xNovo
EndIf

Return(cRet)

/*/{Protheus.doc} SZILinOk
Valida linha de itens do movimento.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function MovTudoOk(oModel)

Local nX         := 0
Local oGrid      := oModel:GetModel("SZISUBST")
Local nOperation := oModel:GetOperation()
Local nLinhas    := oGrid:Length()
Local cItem      := ""
Local cPatrim    := ""
Local cProduto   := ""
Local cISSI      := ""
Local nQuant     := ""
Local cPatOri    := ""
Local cIssiOri   := ""
Local cGrupAtu   := ""
Local cItemDup   := ""
Local aPatOri    := MsvPatOri()
Local nPosRef    := 0
Local nPosOri    := 0
Local aSaveLines := FWSaveRows()
Local cIssiPat   := MsvIssPat()
Local aAcsOri    := If(mv_par01 == 3, MsvAcsIss(), {})
Local nLinAtiv   := 0
Local lRet       := .T.

If nOperation == MODEL_OPERATION_UPDATE
	If nLinhas == 0
		Help(,, "SEMMOV",, "Preencha os equipamentos substitutos.", 1, 0)
		lRet := .F.
	EndIf

	// Substituição de acessórios: exige ao menos uma linha ativa no grid dos
	// itens substitutos (linha deletada não conta).
	If mv_par01 == 3
		For nX := 1 to nLinhas
			If !oGrid:IsDeleted(nX)
				nLinAtiv++
			EndIf
		Next nX

		If nLinAtiv == 0
			Help(,, "SEMACES",, "Informe ao menos um acessório substituto para o patrimônio selecionado.", 1, 0)
			lRet := .F.
		EndIf
	EndIf

	For nX := 1 to nLinhas
		oGrid:GoLine(nX)

		If !oGrid:IsDeleted()
			cItem      := oGrid:GetValue("ZI_ITEM", nX, oModel)
			cPatrim    := oGrid:GetValue("ZI_PATRIM", nX, oModel)
			cProduto   := oGrid:GetValue("ZI_PRODUTO", nX, oModel)
			cISSI      := oGrid:GetValue("ZI_ISSI", nX, oModel)
			nQuant     := oGrid:GetValue("ZI_QUANT", nX, oModel)

			// Exige a referência do patrimônio original desta linha substituta.
			// Referência de linha estornada/deletada não é considerada.
			nPosRef  := MsvRefLin(nX)
			cPatOri  := If(nPosRef > 0, aRefSubs[nPosRef][3], "")
			cIssiOri := If(nPosRef > 0, aRefSubs[nPosRef][4], "")
			cGrupAtu := If(nPosRef > 0, aRefSubs[nPosRef][5], "")

			If mv_par01 == 3
				// Acessórios: a origem é a ISSI do patrimônio informado no
				// Pergunte; não há amarração linha a linha por patrimônio.
				If !Empty(cIssiPat) .and. AllTrim(cISSI) <> AllTrim(cIssiPat)
					Help(,, "ISSIDIF",, "[Item: " + cItem + "] A ISSI da linha deve ser a ISSI do patrimônio selecionado [" +;
						AllTrim(cIssiPat) + "].", 1, 0)
					lRet := .F.
				EndIf

				If !Empty(cPatrim)
					Help(,, "ACESPAT",, "[Item: " + cItem + "] Na troca de acessórios o item não pode ter patrimônio.", 1, 0)
					lRet := .F.
				EndIf

				// O produto substituto tem que pertencer aos acessórios ativos
				// da ISSI selecionada no documento original.
				If !Empty(cProduto) .and. Len(aAcsOri) > 0
					If aScan(aAcsOri, {|x| AllTrim(x[3]) == AllTrim(cProduto)}) == 0
						Help(,, "PRDNOISS",, "[Item: " + cItem + "] O produto [" + AllTrim(cProduto) +;
							"] não pertence aos acessórios da ISSI [" + AllTrim(cIssiPat) + "].", 1, 0)
						lRet := .F.
					EndIf
				EndIf
			ElseIf nPosRef == 0 .or. Empty(cPatOri)
				Help(,, "SEMORIG",, "[Item: " + cItem + "] Informe qual patrimônio do documento original está sendo substituído.", 1, 0)
				lRet := .F.
			Else
				// Reconsulta o documento original: só vale patrimônio ainda ativo (ZI_STATUS == "A").
				nPosOri := aScan(aPatOri, {|x| AllTrim(x[2]) == AllTrim(cPatOri) .and. AllTrim(x[3]) == AllTrim(cIssiOri)})

				If nPosOri == 0
					Help(,, "ORIINAT",, "[Item: " + cItem + "] O patrimônio [" + AllTrim(cPatOri) +;
						"] não está mais ativo no documento original.", 1, 0)
					lRet := .F.
				EndIf

				// Nenhum patrimônio de origem pode ser referenciado por outro kit / item substituto.
				// Linhas do mesmo kit (mesmo agrupamento) compartilham o patrimônio de origem.
				cItemDup := MsvPatDup(oGrid, oModel, nX, cPatOri, cGrupAtu)

				If !Empty(cItemDup)
					Help(,, "ORIDUPL",, "[Item: " + cItemDup + "] O patrimônio [" + AllTrim(cPatOri) +;
						"] já foi referenciado em outro item substituto.", 1, 0)
					lRet := .F.
				EndIf
			EndIf

			If Empty(cISSI)
				Help(,, "ISSIVAZIO",, "[Item: " + cItem + "] Preencha a ISSI.", 1, 0)
				lRet := .F.
			Endif

			If Empty(nQuant)
				Help(,, "QTDZERO",, "[Item: " + cItem + "] Preencha a quantidade.", 1, 0)
				lRet := .F.
			Endif

			If Empty(cProduto)
				Help(,, "PRDNOEX",, "[Item: " + cItem + "] Preencha o produto.", 1, 0)
				lRet := .F.
			Else
				if Empty(cPatrim)
					If U_TemPatrim(cProduto)
						Help(,, "PATRVAZIO",, "O produto [" + AllTrim(cProduto) + "] controla patrimônio e deve ter o número informado.", 1, 0)
						lRet := .F.
					EndIf
				EndIf
			EndIf
		EndIf
	Next nX

	// Limite: não pode haver mais referências do que patrimônios ativos no documento original.
	If MsvQtdRef() > Len(aPatOri)
		Help(,, "MAXKIT",, "O documento original tem apenas " + AllTrim(Str(Len(aPatOri))) +;
			" patrimônio(s) ativo(s); revise os itens substitutos.", 1, 0)
		lRet := .F.
	EndIf
EndIf

FWRestRows(aSaveLines)

Return(lRet)

/*/{Protheus.doc} MsvIssPat
Devolve a ISSI do patrimônio informado no Pergunte (mv_par03), usada como filtro
da substituição de acessórios (mv_par01 == 3).

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12

@return character, ISSI do patrimônio; "" nas demais substituições.
/*/
Static Function MsvIssPat()

Local cRet := ""

If mv_par01 == 3 .and. !Empty(cISSI)
    cRet := AllTrim(cISSI)
EndIf

Return(cRet)

/*/{Protheus.doc} MsvAcsOri
Devolve os produtos dos acessórios ativos (ZI_PATRIM vazio) da ISSI do
patrimônio informado, dentro do documento original.

Serve de base para criticar, em MovTudoOk(), o item substituto cujo produto não
pertence à ISSI selecionada.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12

@return array, Lista de ZI_PRODUTO dos acessórios da ISSI.
/*/
Static Function MsvAcsOri()

Local aArea   := GetArea()
Local aAreaZI := SZI->(GetArea())
Local cIssiPt := MsvIssPat()
Local aRet    := {}

If Empty(cIssiPt)
    RestArea(aAreaZI)
    RestArea(aArea)
    Return(aRet)
EndIf

SZI->(DbSetOrder(1)) // Cód.Posto + Localidade + Documento + Item

If SZI->(DbSeek(xFilial("SZI") + cCodPost + cLocalid + cDocumento))
    While SZI->ZI_FILIAL == xFilial("SZI") .and.;
        SZI->ZI_CODPOST == cCodPost .and.;
        SZI->ZI_LOCALID == cLocalid .and.;
        SZI->ZI_DOC == cDocumento .and. !SZI->(EOF())

        If SZI->ZI_STATUS == "A" .and. Empty(SZI->ZI_PATRIM) .and.;
            AllTrim(SZI->ZI_ISSI) == cIssiPt

            If aScan(aRet, {|x| AllTrim(x) == AllTrim(SZI->ZI_PRODUTO)}) == 0
                AAdd(aRet, SZI->ZI_PRODUTO)
            EndIf
        EndIf

        SZI->(DbSkip())
    End
EndIf

RestArea(aAreaZI)
RestArea(aArea)

Return(aRet)

/*/{Protheus.doc} MsvPatDup
Verifica se o patrimônio de origem da linha corrente já está referenciado por
OUTRO agrupamento de kit / item substituto.

Percorre o grid pulando a própria linha em avaliação e as linhas deletadas,
evitando o falso positivo que disparava o help ORIDUPL na substituição de kit
(todas as linhas do mesmo kit apontam para o mesmo patrimônio substituído).

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12

@param oGrid, object, Grid dos itens substitutos (SZISUBST).
@param oModel, object, Modelo de dados ativo.
@param nLinAtu, numeric, Linha corrente do grid em avaliação.
@param cPatOri, character, Patrimônio de origem referenciado pela linha corrente.
@param cGrupAtu, character, Agrupamento de kit da linha corrente.

@return character, ZI_ITEM da linha conflitante; "" quando não há duplicidade.
/*/
Static Function MsvPatDup(oGrid, oModel, nLinAtu, cPatOri, cGrupAtu)

Local nI      := 0
Local nPosRef := 0
Local cPatCmp := ""
Local cGrpCmp := ""
Local cRet    := ""

Default cGrupAtu := ""

If oGrid == Nil .or. Empty(cPatOri)
    Return("")
EndIf

For nI := 1 to oGrid:Length()
    // Pula a própria linha em avaliação.
    If nI == nLinAtu
        Loop
    EndIf

    oGrid:GoLine(nI)

    // Linha apagada no grid não gera duplicidade.
    If oGrid:IsDeleted()
        Loop
    EndIf

    // Só compara com linha que tem amarração ativa; linha estornada não gera
    // duplicidade (evita o help ORIDUPL numa nova amarração do mesmo patrimônio).
    nPosRef := MsvRefLin(nI)

    If nPosRef == 0
        Loop
    EndIf

    cPatCmp := aRefSubs[nPosRef][3]
    cGrpCmp := aRefSubs[nPosRef][5]

    If AllTrim(cPatCmp) <> AllTrim(cPatOri)
        Loop
    EndIf

    // Mesmo kit (mesmo agrupamento) pode repetir o patrimônio de origem.
    If !Empty(cGrupAtu) .and. AllTrim(cGrpCmp) == AllTrim(cGrupAtu)
        Loop
    EndIf

    cRet := oGrid:GetValue("ZI_ITEM", nI, oModel)
    Exit
Next nI

// Devolve o grid para a linha que estava sendo avaliada.
If nLinAtu >= 1 .and. nLinAtu <= oGrid:Length()
    oGrid:GoLine(nLinAtu)
EndIf

Return(cRet)

/*/{Protheus.doc} AtuaMov
Gravação do movimento.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function AtuaMov(oModel)

Local nX         := 0
Local oModelSZH  := oModel:GetModel("SZHMASTER")
Local oModelSZI  := oModel:GetModel("SZISUBST")
Local nOperation := oModel:GetOperation()
Local cCodPost   := oModelSZH:GetValue("ZH_CODPOST")
Local cLocalid   := oModelSZH:GetValue("ZH_LOCALID")
Local cCCusto    := oModelSZH:GetValue("ZH_CC")
Local cResp      := oModelSZH:GetValue("ZH_CODRESP")
Local cChamado   := oModelSZH:GetValue("ZH_CHAMADO")
Local cMotivo    := oModelSZH:GetValue("ZH_MOTIVO")
Local cIssiOri   := ""
Local cIssiNew   := ""
Local cItemOri   := ""
Local cPatOri    := ""
Local cChvBx     := ""
Local cIssiGrv   := ""
Local cPatGrv    := ""
Local cSeqGrv    := ""
Local cChvIss    := ""
Local nPosRef    := 0
// Pares de ISSI (origem x nova) já trocados nos acessórios; o kit pode gerar
// várias linhas substitutas com a mesma ISSI de origem.
Local aIssTrc    := {}
// Origens já baixadas (evita baixar duas vezes o mesmo patrimônio).
// mv_par01 == 1 / 3: a chave é a ISSI de origem (baixa a ISSI inteira).
// mv_par01 == 2: a chave é ISSI + ZI_ITEM + ZI_PATRIM da origem (baixa pontual).
Local aIssiBx    := {}
// Itens do documento original que permaneceram (nao deletados) no grid dos
// itens substitutos. Usado na substituicao de acessorios (mv_par01 == 3), onde
// o grid SZISUBST e carregado com os proprios itens do documento original.
Local aItGrid    := {}
Local lItGrid    := .F.
Local cItGrid    := ""
Local cDocGrd    := ""

SZI->(DbSetOrder(5)) // ISSI + Documento + Item
SZJ->(DbSetOrder(3)) // Patrimônio
SZK->(DbSetOrder(1)) // Cód.Posto + Localidade + Kit + Patromônio
SZL->(DbSetOrder(1)) // Cód.Posto + Localidade + Kit
SZM->(DbSetOrder(1)) // Cód.Posto + Localidade + Documento + Item

If nOperation == MODEL_OPERATION_UPDATE
    // Grava o kit/Patrimônio/acessório novo.
    cNewDoc := GetSXENum("SZH", "ZH_DOC")

    BeginTran()

    RecLock("SZH", .T.)
    SZH->ZH_FILIAL  := xFilial("SZH")
    SZH->ZH_DOC     := cNewDoc
    SZH->ZH_EMISSAO := dDataBase
    SZH->ZH_CODPOST := cCodPost
    SZH->ZH_LOCALID := cLocalid
    SZH->ZH_CC      := cCCusto
    SZH->ZH_CODRESP := cResp
    SZH->ZH_CHAMADO := cChamado
    SZH->ZH_MOTIVO  := cMotivo
    SZH->ZH_STATUS  := "S"
    MsUnlock()

    For nX := 1 to oModelSZI:Length()
        oModelSZI:GoLine(nX)

        If !oModelSZI:IsDeleted()

            // Substituição de acessórios (mv_par01 == 3): a ISSI da linha nova
            // sempre acompanha a ISSI do patrimônio de origem informado no
            // Pergunte; o ZI_NUMSEQ mantém o tratamento atual do documento.
            cIssiGrv := oModelSZI:GetValue("ZI_ISSI", nX, oModel)
            cPatGrv  := oModelSZI:GetValue("ZI_PATRIM", nX, oModel)
            cSeqGrv  := oModelSZI:GetValue("ZI_NUMSEQ", nX, oModel)

            If mv_par01 == 3
                If !Empty(cISSI)
                    cIssiGrv := cISSI
                EndIf

                If Empty(cSeqGrv)
                    cSeqGrv := cNumSeq
                EndIf
            EndIf

            // Grava o item novo.
            RecLock("SZI", .T.)
            SZI->ZI_FILIAL  := xFilial("SZI")
            SZI->ZI_CODPOST := cCodPost
            SZI->ZI_LOCALID := cLocalid
            SZI->ZI_DOC     := cNewDoc
            SZI->ZI_STATUS  := "A"
            SZI->ZI_ITEM    := oModelSZI:GetValue("ZI_ITEM", nX, oModel)
            SZI->ZI_PRODUTO := oModelSZI:GetValue("ZI_PRODUTO", nX, oModel)
            SZI->ZI_PATRIM  := cPatGrv
            SZI->ZI_NUMSER  := oModelSZI:GetValue("ZI_NUMSER", nX, oModel)
            SZI->ZI_ISSI    := cIssiGrv
            SZI->ZI_CODKIT  := oModelSZI:GetValue("ZI_CODKIT", nX, oModel)
            SZI->ZI_QUANT   := oModelSZI:GetValue("ZI_QUANT", nX, oModel)
            SZI->ZI_LOCALIZ := oModelSZI:GetValue("ZI_LOCALIZ", nX, oModel)
            SZI->ZI_DATAMOV := dDataBase
            SZI->ZI_DESCRI  := oModelSZI:GetValue("ZI_DESCRI", nX, oModel)
            SZI->ZI_NUMSEQ  := cSeqGrv
            MsUnlock()

            // Movimenta o estoque.
            U_GravaEst(cCodPost, cLocalid, oModelSZI:GetValue("ZI_PRODUTO", nX, oModel), "01", oModelSZI:GetValue("ZI_QUANT", nX, oModel), "S")

            // Ajusta o status do patrimônio substituído.
            If !Empty(oModelSZI:GetValue("ZI_PATRIM", nX, oModel))
                If SZJ->(DbSeek(xFilial("SZJ") + oModelSZI:GetValue("ZI_PATRIM", nX, oModel)))
                    RecLock("SZJ", .F.)
                    SZJ->ZJ_LOCADO := "S"
                    MsUnlock()
                EndIf

                // Registra o valor da primeira locação caso ainda não tenha sido locado.
                If !SZK->(DbSeek(xFilial("SZK") + cCodPost + cLocalid + oModelSZI:GetValue("ZI_CODKIT", nX, oModel) +;
                    oModelSZI:GetValue("ZI_PATRIM", nX, oModel)))
                    nValor := 0
                    // Se não tem valor de referência do patrimôio anteior, consulta o valor vigente na tabela.
                    If SZL->(DbSeek(xFilial("SZL") + cCodPost + cLocalid + oModelSZI:GetValue("ZI_CODKIT", nX, oModel)))
                        While SZL->ZL_FILIAL == xFilial("SZL") .and.;
                            SZL->ZL_CODPOST == cCodPost .and.;
                            SZL->ZL_LOCALID == cLocalid .and.;
                            SZL->ZL_CODKIT == oModelSZI:GetValue("ZI_CODKIT", nX, oModel) .and. !SZL->(EOF())
                            
                            If SZL->ZL_DATADE <= dDataBase .and. SZL->ZL_DATAATE >= dDataBase
                                nValor := SZL->ZL_VALOR
                                Exit
                            EndIf
                            SZL->(DbSkip())
                        End
                    EndIf

                    // Registra a primeira locação e o respectivo valor.
                    RecLock("SZK", .T.)
                    SZK->ZK_FILIAL  := xFilial("SZK")
                    SZK->ZK_CODPOST := cCodPost
                    SZK->ZK_LOCALID := cLocalid
                    SZK->ZK_CODKIT  := oModelSZI:GetValue("ZI_CODKIT", nX, oModel)
                    SZK->ZK_ENTREGA := dDataBase
                    SZK->ZK_PATRIM  := oModelSZI:GetValue("ZI_PATRIM", nX, oModel)
                    SZK->ZK_VALOR   := nValor
                    MsUnlock()
                EndIf
            EndIf
        EndIf
    Next nX

    // Altera o status dos itens substituídos.
    // Fotografa os itens que permaneceram no grid dos substitutos (linha não
    // deletada). Na troca de acessórios (mv_par01 == 3) o grid SZISUBST é
    // carregado com os próprios itens do documento original, portanto só pode
    // ser baixado o item que o usuário NÃO apagou no grid.
    If mv_par01 == 3
        For nX := 1 to oModelSZI:Length()
            If oModelSZI:IsDeleted(nX)
                Loop
            EndIf

            // A chave leva o documento de origem: com os acessorios vindos de
            // documentos distintos (troca pela ISSI), ZI_ITEM isolado colide
            // entre dois documentos e baixaria o item errado.
            cItGrid := AllTrim(oModelSZI:GetValue("ZI_ITEM", nX, oModel))
            cDocGrd := AllTrim(oModelSZI:GetValue("ZI_DOC", nX, oModel))

            If Empty(cItGrid)
                Loop
            EndIf

            If Empty(cDocGrd)
                cDocGrd := AllTrim(cDocumento)
            EndIf

            cItGrid := cDocGrd + "|" + cItGrid

            If aScan(aItGrid, {|x| AllTrim(x) == cItGrid}) == 0
                AAdd(aItGrid, cItGrid)
            EndIf
        Next nX

        lItGrid := Len(aItGrid) > 0
    EndIf

    For nX := 1 to oModelSZI:Length()
        oModelSZI:GoLine(nX)

        If !oModelSZI:IsDeleted()
            // A baixa é feita na ISSI do patrimônio de origem referenciado pela linha nova.
            // Linha estornada/deletada não baixa ZI_DOCSUBS / ZI_STATUS do documento original.
            nPosRef  := MsvRefLin(nX)
            cItemOri := If(nPosRef > 0, aRefSubs[nPosRef][2], "")
            cPatOri  := If(nPosRef > 0, aRefSubs[nPosRef][3], "")
            cIssiOri := If(nPosRef > 0, aRefSubs[nPosRef][4], "")

            // Kit / patrimônio (mv_par01 == 1 e 2): sem amarração ativa não há
            // o que baixar. A linha estornada ou apagada no grid dos itens
            // substitutos não pode alterar o documento original.
            If mv_par01 <> 3 .and. nPosRef == 0
                Loop
            EndIf

            // Substituição de acessórios: não há amarração de patrimônio pelo
            // botão de kit; a origem é sempre a ISSI do patrimônio informado.
            If mv_par01 == 3 .and. Empty(cIssiOri)
                cIssiOri := cISSI
            EndIf

            If Empty(cIssiOri)
                Loop
            EndIf

            // Substituição por patrimônio: a baixa é pontual, apenas no registro do
            // patrimônio original. Os acessórios da ISSI permanecem ativos (só trocam
            // de ISSI mais adiante), portanto não geram estoque nem perda.
            If mv_par01 == 2
                If Empty(cPatOri)
                    Loop
                EndIf

                cChvBx := AllTrim(cIssiOri) + "|" + AllTrim(cItemOri) + "|" + AllTrim(cPatOri)
            Else
                cChvBx := AllTrim(cIssiOri)
            EndIf

            // Cada origem é baixada uma única vez.
            If aScan(aIssiBx, {|x| AllTrim(x) == cChvBx}) > 0
                Loop
            EndIf

            AAdd(aIssiBx, cChvBx)

            // Varre todos os itens da ISSI de origem (patrimônio + acessórios) no documento original.
            SZI->(DbSetOrder(5)) // ISSI + Documento + Item
            SZI->(DbSeek(xFilial("SZI") + cIssiOri))

            While SZI->ZI_FILIAL == xFilial("SZI") .and.;
                AllTrim(SZI->ZI_ISSI) == AllTrim(cIssiOri) .and. !SZI->(EOF())

                // Kit / patrimonio (mv_par01 == 1 e 2): a baixa continua presa
                // ao documento do cabecalho. Acessorios (mv_par01 == 3) sao
                // localizados pela ISSI, portanto podem estar em outro
                // documento; nesse caso o unico documento que NAO pode ser
                // baixado e o que acabou de ser gerado (cNewDoc).
                If mv_par01 == 3
                    If AllTrim(SZI->ZI_DOC) == AllTrim(cNewDoc) .or. SZI->ZI_STATUS <> "A"
                        SZI->(DbSkip())
                        Loop
                    EndIf
                Else
                    If AllTrim(SZI->ZI_DOC) <> AllTrim(cDocumento) .or. SZI->ZI_STATUS <> "A"
                        SZI->(DbSkip())
                        Loop
                    EndIf
                EndIf

                // mv_par01 == 2: baixa somente a linha do patrimônio original
                // referenciado; acessório (ZI_PATRIM vazio) e outro patrimônio /
                // outro item da mesma ISSI ficam intactos.
                If mv_par01 == 2
                    If Empty(SZI->ZI_PATRIM)
                        SZI->(DbSkip())
                        Loop
                    EndIf

                    If AllTrim(SZI->ZI_PATRIM) <> AllTrim(cPatOri)
                        SZI->(DbSkip())
                        Loop
                    EndIf

                    If !Empty(cItemOri) .and. AllTrim(SZI->ZI_ITEM) <> AllTrim(cItemOri)
                        SZI->(DbSkip())
                        Loop
                    EndIf
                EndIf

                // mv_par01 == 3: baixa somente os acessórios (ZI_PATRIM vazio)
                // da ISSI do patrimônio escolhido; o próprio patrimônio e os
                // acessórios das demais ISSIs seguem ativos.
                If mv_par01 == 3
                    If !Empty(SZI->ZI_PATRIM)
                        SZI->(DbSkip())
                        Loop
                    EndIf

                    If !Empty(cISSI) .and. AllTrim(SZI->ZI_ISSI) <> AllTrim(cISSI)
                        SZI->(DbSkip())
                        Loop
                    EndIf

                    // Só baixa o acessório que permaneceu no grid dos itens
                    // substitutos; o que o usuário deletou continua ativo no
                    // documento original (não muda status, não gera estoque).
                    If lItGrid .and. aScan(aItGrid, {|x| AllTrim(x) == AllTrim(SZI->ZI_DOC) + "|" + AllTrim(SZI->ZI_ITEM)}) == 0
                        SZI->(DbSkip())
                        Loop
                    EndIf
                EndIf

                RecLock("SZI", .F.)
                SZI->ZI_DOCSUBS := cNewDoc
                SZI->ZI_DATADEV := dDataBase
                SZI->ZI_STATUS := If(mv_par02 == 1, "R", "S") // R = Reposição / S = Substituído
                MsUnlock()

                // Atualiza o estoque do item substituído.
                If mv_par02 == 1 // reposição
                    U_GravaEst(cCodPost, cLocalid, SZI->ZI_PRODUTO, "03", SZI->ZI_QUANT, "E")

                    If !Empty(SZI->ZI_PATRIM)
                        If SZJ->(DbSeek(xFilial("SZJ") + SZI->ZI_PATRIM))
                            RecLock("SZJ", .F.)
                            // Teve perda, inutiliza o patrimônio.
                            SZJ->ZJ_LOCADO := "P"
                            MsUnlock()
                        EndIf
                    EndIf

                    // Registra no arquivo de perdas.
                    RecLock("SZM", .T.)
                    SZM->ZM_FILIAL  := xFilial("SZM")
                    SZM->ZM_CODPOST := cCodPost
                    SZM->ZM_LOCALID := cLocalid
                    SZM->ZM_DOC     := SZI->ZI_DOC
                    SZM->ZM_DATA    := dDataBase
                    SZM->ZM_ITEM    := SZI->ZI_ITEM
                    SZM->ZM_PRODUTO := SZI->ZI_PRODUTO
                    SZM->ZM_PATRIM  := SZI->ZI_PATRIM
                    SZM->ZM_NUMSER  := SZI->ZI_NUMSER
                    SZM->ZM_QUANT   := SZI->ZI_QUANT
                    MsUnlock()
                Else
                    U_GravaEst(cCodPost, cLocalid, SZI->ZI_PRODUTO, "02", SZI->ZI_QUANT, "E")

                    If !Empty(SZI->ZI_PATRIM)
                        If SZJ->(DbSeek(xFilial("SZJ") + SZI->ZI_PATRIM))
                            RecLock("SZJ", .F.)
                            // Muda o status para manutenção, pois, está indo para o aramzém de manutenção.
                            SZJ->ZJ_LOCADO := "M"
                            MsUnlock()
                        EndIf
                    EndIf
                EndIf

                SZI->(DbSkip())
            End
        EndIf
    Next nX

    // Substituição do patrimônio deve atualizar a ISSI dos acessários para a
    // ISSI do rádio novo. Mas não atualiza nada no estoque.
    If mv_par01 == 2
        // ISSI de origem (patrimônio substituído) x ISSI do rádio novo, par a par:
        // cada linha ativa do grid substituto troca a ISSI dos SEUS acessórios.
        For nX := 1 to oModelSZI:Length()
            If oModelSZI:IsDeleted(nX)
                Loop
            EndIf

            nPosRef := MsvRefLin(nX)

            If nPosRef == 0 .or. Empty(aRefSubs[nPosRef][4])
                Loop
            EndIf

            cIssiOri := aRefSubs[nPosRef][4]
            cIssiNew := oModelSZI:GetValue("ZI_ISSI", nX, oModel)

            // Sem ISSI de origem / nova, ou ISSI igual: nada a atualizar.
            If Empty(cIssiOri) .or. Empty(cIssiNew) .or. AllTrim(cIssiOri) == AllTrim(cIssiNew)
                Loop
            EndIf

            cChvIss := AllTrim(cIssiOri) + "|" + AllTrim(cIssiNew)

            // O kit gera várias linhas com a mesma origem: executa o par uma única vez.
            If aScan(aIssTrc, {|x| AllTrim(x) == cChvIss}) > 0
                Loop
            EndIf

            AAdd(aIssTrc, cChvIss)

            MsvTrcIss(cIssiOri, cIssiNew, cDocumento)
        Next nX
    EndIf

    ConfirmSX8()

    Endtran()
EndIf

Return(.T.)

/*/{Protheus.doc} MsvTrcIss
Troca a ISSI dos acessórios ativos do documento original: os acessórios
(ZI_PATRIM vazio) que estavam amarrados à ISSI do patrimônio substituído passam
a apontar para a ISSI do rádio novo. Não movimenta estoque.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12

@param cIssiOri, character, ISSI do patrimônio original (substituído).
@param cIssiNew, character, ISSI do patrimônio novo (substituto).
@param cDocOri, character, Documento original dos acessórios.

@return nil
/*/
Static Function MsvTrcIss(cIssiOri, cIssiNew, cDocOri)

Local cQuery := ""
Local nRet   := 0

Default cIssiOri := ""
Default cIssiNew := ""
Default cDocOri  := ""

// Par incompleto ou ISSI igual: nada a atualizar.
If Empty(cIssiOri) .or. Empty(cIssiNew) .or. AllTrim(cIssiOri) == AllTrim(cIssiNew)
    Return
EndIf

cQuery := "UPDATE " + RetSQLName("SZI")
cQuery += " SET ZI_ISSI = '" + AllTrim(cIssiNew) + "'"
cQuery += " WHERE "
cQuery += "ZI_PATRIM = '' AND "
cQuery += "ZI_ISSI = '" + AllTrim(cIssiOri) + "' AND "
cQuery += "ZI_DOC = '" + AllTrim(cDocOri) + "' AND "
cQuery += "ZI_STATUS = 'A' AND "
cQuery += "D_E_L_E_T_ = ''"

nRet := TCSQLExec(cQuery)

If nRet <> 0
    DisarmTransaction()

    Help(,, "ERRISSI",, "Falha ao atualizar a ISSI dos acessórios [ISSI origem " + AllTrim(cIssiOri) +;
        " / ISSI nova " + AllTrim(cIssiNew) + "]. " + TCSQLError(), 1, 0)
EndIf

Return
