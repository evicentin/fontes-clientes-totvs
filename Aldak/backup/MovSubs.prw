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

SZH->(DbSetOrder(2))

If !Pergunte("SUBSTEQUIP", .T.)
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

oModel := MPFormModel():New("MOVSUBSM", /*bPre*/, {|oModel| MovTudoOk(oModel)}, { |oMdl| AtuaMov(oMdl) }, /*bCancel*/)

oStruSZH:SetProperty("ZH_DOC", MODEL_FIELD_WHEN, FwBuildFeature(STRUCT_FEATURE_WHEN, ".F."))
oStruSZH:SetProperty("ZH_EMISSAO", MODEL_FIELD_WHEN, FwBuildFeature(STRUCT_FEATURE_WHEN, ".F."))
oStruSZH:SetProperty("ZH_CODPOST", MODEL_FIELD_WHEN, FwBuildFeature(STRUCT_FEATURE_WHEN, ".F."))
oStruSZH:SetProperty("ZH_LOCALID", MODEL_FIELD_WHEN, FwBuildFeature(STRUCT_FEATURE_WHEN, ".F."))
oStruSZH:SetProperty("ZH_CC", MODEL_FIELD_WHEN, FwBuildFeature(STRUCT_FEATURE_WHEN, ".F."))
oStruSZH:SetProperty("ZH_CODRESP", MODEL_FIELD_WHEN, FwBuildFeature(STRUCT_FEATURE_WHEN, ".F."))

oModel:AddFields("SZHMASTER",, oStruSZH)

oModel:AddGrid("SZIORIGEM", "SZHMASTER", oSZIOri)
oModel:AddGrid("SZISUBST", "SZHMASTER", oSZISub)

oModel:SetRelation("SZIORIGEM", {{"ZI_FILIAL", "xFilial('SZI')"}, {"ZI_CODPOST", "ZH_CODPOST"}, {"ZI_LOCALID", "ZH_LOCALID"},;
                                 {"ZI_DOC", "ZH_DOC"}}, SZI->(IndexKey(1)))

If mv_par01 == 2
    oModel:GetModel("SZIORIGEM"):SetLoadFilter(Nil, "ZI_PATRIM <> ''")
ElseIf mv_par01 == 3
    oModel:GetModel("SZIORIGEM"):SetLoadFilter(Nil, "ZI_PATRIM = ''")
    oModel:GetModel("SZISUBST"):SetLoadFilter(Nil, "ZI_PATRIM = ''")

    oModel:SetRelation("SZISUBST", {{"ZI_FILIAL", "xFilial('SZI')"}, {"ZI_CODPOST", "ZH_CODPOST"}, {"ZI_LOCALID", "ZH_LOCALID"},;
                                    {"ZI_DOC", "ZH_DOC"}}, SZI->(IndexKey(1)))
EndIf

oModel:SetPrimaryKey({})

// oModel:GetModel("SZHMASTER"):SetOnlyView(.T.)
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
                                                                    "ZI_DPSSUB|ZI_DPSMC|ZI_DPSEQDV|"})
Local oSZISub    := FWFormStruct(2, "SZI", {|x| !AllTrim(x) + "|" $ "ZI_CODPOST|ZI_LOCALID|ZI_STATUS|ZI_DATADEV|ZI_PERDA|ZI_DOCSUBS|ZI_DPSMI|ZI_DPSEQ|"+;
                                                                    "ZI_DPSKIT|ZI_DPSSUB|ZI_DPSMC|ZI_DPSEQDV|"})
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

If mv_par01 == 1
    oBtn := TButton():New(10, 10, "+ Kit", oPanel, {|| PesqKit()}, 80, 20,,,,.T.)
ElseIf mv_par01 == 2
    oBtn := TButton():New(10, 10, "+ Patrimônio", oPanel, {|| LoadNewPat()}, 120, 20,,,,.T.)
EndIf

Return

/*/{Protheus.doc} ValidaSubs
Valida se o documento tem itens ativos.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ValidaSubs()

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
    ElseIf mv_par01 == 3
        If !Empty(SZI->ZI_PATRIM)
            SZI->(DbSkip())
            Loop
        EndIf
    EndIf

    lRet := .T.

    SZI->(DbSkip())
End

If !lRet
    Help(,, "SEMIT",, "Esse documento não tem nenhum item ativo para ser substituído", 1, 0)
EndIf

Return(lRet)

/*/{Protheus.doc} ButtonKit
Pesquisa do Kit.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function PesqKit()

Local oSay1, oSay2, oSay3
Local oGet1, oGet2, oGet3
Local oButton1, oButton2
Local oDlg
Local oModel   := FWModelActive()
Local oGrid    := oModel:GetModel("SZIORIGEM")
Local cKit     := Space(6)
Local cISSI    := If(mv_par01 == 3, AllTrim(oGrid:GetValue("ZI_ISSI", 1, oModel)), Space(14))
Local cLocaliz := oGrid:GetValue("ZI_LOCALIZ", 1, oModel)

DEFINE MSDIALOG oDlg TITLE "Pesquisa de Kits" FROM 000, 000  TO 220, 500 COLORS 0, 16777215 PIXEL

@ 005, 005 SAY oSay1 PROMPT "Kit" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
@ 014, 005 MSGET oGet1 VAR cKit VALID(cISSI := If(mv_par01 == 3, AllTrim(oGrid:GetValue("ZI_ISSI", 1, oModel)), Space(14))) SIZE 060, 010 OF oDlg COLORS 0, 16777215 F3 "Z20" PIXEL
@ 030, 005 SAY oSay2 PROMPT "ISSI" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
@ 056, 005 SAY oSay3 PROMPT "Localização" SIZE 035, 007 OF oDlg COLORS 0, 16777215 PIXEL
@ 039, 005 MSGET oGet2 VAR cISSI SIZE 060, 010 OF oDlg COLORS 0, 16777215 PIXEL
@ 065, 005 MSGET oGet3 VAR cLocaliz SIZE 237, 010 OF oDlg COLORS 0, 16777215 PIXEL

@ 094, 163 BUTTON oButton1 PROMPT "Confirmar" ACTION(LoadKit(cKit, cISSI, cLocaliz), oDlg:End()) SIZE 037, 012 OF oDlg PIXEL
@ 094, 205 BUTTON oButton2 PROMPT "Cancelar" ACTION(oDlg:End()) SIZE 037, 012 OF oDlg PIXEL

ACTIVATE MSDIALOG oDlg CENTERED

Return

/*/{Protheus.doc} ButtonKit
Carrega o kit substituto.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function LoadKit(cKit, cISSI, cLocaliz)

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

		If !lTemSaldo
			oGrid:DeleteLine()
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
Local oModelSZI  := oModel:GetModel("SZIORIGEM")
Local oGrid      := oModel:GetModel("SZISUBST")
Local cCodPost   := oModelSZH:GetValue("ZH_CODPOST")
Local cLocalid   := oModelSZH:GetValue("ZH_LOCALID")
Local cKit       := oModelSZI:GetValue("ZI_CODKIT", 1, oModel)
Local cISSI      := Space(14)
Local cLocaliz   := oModelSZI:GetValue("ZI_LOCALIZ", 1, oModel)
Local cNumSeq    := U_RetNumSeq()
Local cProduto   := ""
Local cPatrim    := ""
Local cNumSer    := ""
Local lTemSaldo  := .T.

SB1->(DbSetOrder(1)) // Código
SZA->(DbSetOrder(1)) // Produto + Prod. similar
SZF->(DbSetOrder(1)) // Cod.posto + Localidade + Produto + Armazém

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

    If !lTemSaldo
        oGrid:DeleteLine()
    EndIf

    oGrid:GoLine(1)

    If oView <> Nil
        oView:Refresh()
    EndIf
EndIf

Return

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
Local aSaveLines := FWSaveRows()
Local lRet       := .T.

If nOperation == MODEL_OPERATION_UPDATE
	If nLinhas == 0
		Help(,, "SEMMOV",, "Preencha os equipamentos substitutos.", 1, 0)
		lRet := .F.
	EndIf

	For nX := 1 to nLinhas
		oGrid:GoLine(nX)

		If !oGrid:IsDeleted()
			cItem      := oGrid:GetValue("ZI_ITEM", nX, oModel)
			cPatrim    := oGrid:GetValue("ZI_PATRIM", nX, oModel)
			cProduto   := oGrid:GetValue("ZI_PRODUTO", nX, oModel)
			cISSI      := oGrid:GetValue("ZI_ISSI", nX, oModel)
			nQuant     := oGrid:GetValue("ZI_QUANT", nX, oModel)

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
EndIf

FWRestRows(aSaveLines)

Return(lRet)

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
Local cQuery     := ""
Local nOperation := oModel:GetOperation()
Local cCodPost   := oModelSZH:GetValue("ZH_CODPOST")
Local cLocalid   := oModelSZH:GetValue("ZH_LOCALID")
Local cCCusto    := oModelSZH:GetValue("ZH_CC")
Local cResp      := oModelSZH:GetValue("ZH_CODRESP")
Local cChamado   := oModelSZH:GetValue("ZH_CHAMADO")
Local cMotivo    := oModelSZH:GetValue("ZH_MOTIVO")

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

            // Grava o item novo.
            RecLock("SZI", .T.)
            SZI->ZI_FILIAL  := xFilial("SZI")
            SZI->ZI_CODPOST := cCodPost
            SZI->ZI_LOCALID := cLocalid
            SZI->ZI_DOC     := cNewDoc
            SZI->ZI_STATUS  := "A"
            SZI->ZI_ITEM    := oModelSZI:GetValue("ZI_ITEM", nX, oModel)
            SZI->ZI_PRODUTO := oModelSZI:GetValue("ZI_PRODUTO", nX, oModel)
            SZI->ZI_PATRIM  := oModelSZI:GetValue("ZI_PATRIM", nX, oModel)
            SZI->ZI_NUMSER  := oModelSZI:GetValue("ZI_NUMSER", nX, oModel)
            SZI->ZI_ISSI    := oModelSZI:GetValue("ZI_ISSI", nX, oModel)
            SZI->ZI_CODKIT  := oModelSZI:GetValue("ZI_CODKIT", nX, oModel)
            SZI->ZI_QUANT   := oModelSZI:GetValue("ZI_QUANT", nX, oModel)
            SZI->ZI_LOCALIZ := oModelSZI:GetValue("ZI_LOCALIZ", nX, oModel)
            SZI->ZI_DATAMOV := dDataBase
            SZI->ZI_DESCRI  := oModelSZI:GetValue("ZI_DESCRI", nX, oModel)
            SZI->ZI_NUMSEQ  := oModelSZI:GetValue("ZI_NUMSEQ", nX, oModel)
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
    For nX := 1 to oModelSZI:Length()
        oModelSZI:GoLine(nX)

        If !oModelSZI:IsDeleted()
            cISSI := oModelSZI:GetValue("ZI_ISSI", nX, oModel)
            cDoc  := oModelSZI:GetValue("ZI_DOC", nX, oModel)
            cItem := oModelSZI:GetValue("ZI_ITEM", nX, oModel)

            If SZI->(DbSeek(xFilial("SZI") + cISSI + cDoc + cItem))
                RecLock("SZI", .F.)
                SZI->ZI_DOCSUBS := cNewDoc
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
            EndIf
        EndIf
    Next nX

    // Substituição do patrimônio deve atualizar a ISSI dos acessários para a
    // ISSI do rádio novo. Mas não atualiza nada no estoque.
    If mv_par01 == 2
        cQuery := "UPDATE " + RetSQLName("SZI")
        cQuery += " SET ZI_ISSI = '" + oModelSZI:GetValue("ZI_ISSI", 1, oModel) + "'"
        cQuery += " WHERE "
        cQuery += "ZI_PATRIM = '' AND "
        cQuery += "ZI_ISSI = '" + cISSI + "' AND "
        cQuery += "ZI_STATUS = 'A' AND "
        cQuery += "D_E_L_E_T_ = ''"
    
        TCSQLExec(cQuery)
    EndIf

    ConfirmSX8()

    Endtran()
EndIf

Return(.T.)
