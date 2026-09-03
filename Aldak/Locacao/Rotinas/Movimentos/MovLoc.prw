#Include "totvs.ch"
#Include "fwmvcdef.ch"

/*/{Protheus.doc} MOVLOC
Movimento de Locação.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function MOVLOC()

Local oBrowse

Private lAddLine := .F.

oBrowse := FWMBrowse():New()
oBrowse:SetAlias("SZH")
oBrowse:SetDescription("Movimento de Locação")

oBrowse:AddLegend('ZH_STATUS=="A"', "GREEN", "Entrega"     , "1")
oBrowse:AddLegend('ZH_STATUS=="S"', "BLUE" , "Substituição", "1")
oBrowse:AddLegend('ZH_STATUS=="D"', "BLACK", "Devolução"   , "1")
oBrowse:AddLegend('ZH_STATUS=="P"', "RED"  , "Paralisado"  , "1")

oBrowse:SetFilterDefault(U_MBLocxUsr(1, "SZH"))

oBrowse:Activate()

Return

/*/{Protheus.doc} MENUDEF
Menu de opções do Cadastro

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function MenuDef()

Local aRotina := {}

ADD OPTION aRotina TITLE "Visualizar"         ACTION "VIEWDEF.MOVLOC" OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE "Incluir"            ACTION "VIEWDEF.MOVLOC" OPERATION 3 ACCESS 0
ADD OPTION aRotina TITLE "Paralisar/reativar" ACTION "VIEWDEF.MOVLOC" OPERATION 4 ACCESS 0
ADD OPTION aRotina TITLE "Pesq. Patrimonio"	  ACTION "U_PesqPatrim"   OPERATION 1 ACCESS 0 
ADD OPTION aRotina TITLE "Limpar Filtro"	  ACTION "U_LimpaFiltro"  OPERATION 1 ACCESS 0 
ADD OPTION aRotina TITLE "Estornar"           ACTION "VIEWDEF.MOVLOC" OPERATION 5 ACCESS 0
ADD OPTION aRotina TITLE "Substituir"         ACTION "U_MOVSUBS"   	  OPERATION 1 ACCESS 0 
ADD OPTION aRotina TITLE "Devolver"		      ACTION "U_MovDev"   	  OPERATION 1 ACCESS 0 
ADD OPTION aRotina TITLE "Termo Entrega"	  ACTION "U_TermoEnt" 	  OPERATION 1 ACCESS 0 
ADD OPTION aRotina TITLE "Termo Subst."	      ACTION "U_TermoSubst"	  OPERATION 1 ACCESS 0 
ADD OPTION aRotina TITLE "Termo Devol."	      ACTION "U_TermoDevol"   OPERATION 1 ACCESS 0 

Return(aRotina)

/*/{Protheus.doc} MODELDEF
Modelo de Dados do MVC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ModelDef()

Local oModel
Local oStruSZH := FWFormStruct(1, "SZH")
Local oStruSZI := FWFormStruct(1, "SZI")

oStruSZH:SetProperty('ZH_EMISSAO', MODEL_FIELD_INIT , {|| dDataBase})
oStruSZH:SetProperty('ZH_STATUS', MODEL_FIELD_INIT , {|| 'A'})

oStruSZI:SetProperty("ZI_PRODUTO", MODEL_FIELD_VALID, FwBuildFeature(STRUCT_FEATURE_VALID, "U_GetLineData()"))

oModel := MPFormModel():New("MOVLOCM" , /*bPreValidacao*/, {|oModel| MovTudoOk(oModel)}, { |oMdl| AtuaMov(oMdl) }, /*bCancel*/)

oModel:AddFields("SZHMASTER",, oStruSZH)

oModel:AddGrid("SZIDETAIL", "SZHMASTER", oStruSZI)

oModel:SetRelation("SZIDETAIL", {{"ZI_FILIAL", "xFilial('SZI')"}, {"ZI_CODPOST", "ZH_CODPOST"}, {"ZI_LOCALID", "ZH_LOCALID"},;
    {"ZI_DOC", "ZH_DOC"}}, SZI->(IndexKey(1)))

oModel:SetPrimaryKey({})

oModel:SetDescription("Movimentos")
oModel:GetModel("SZHMASTER"):SetDescription("Dados do Movimento")
oModel:GetModel("SZIDETAIL"):SetDescription("Dados dos Itens dos Movimentos")

Return(oModel)

/*/{Protheus.doc} VIEWDEF
View do MVC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ViewDef()

Local oView
Local oStruSZH   := FWFormStruct(2, "SZH", {|cCampo| AllTrim(cCampo)+"|"$ "ZH_STATUS|ZH_DOC|ZH_EMISSAO|ZH_CODPOST|ZH_DESCPOS|ZH_LOCALID|ZH_DESCLOC|"+;
                                                                          "ZH_CC|ZH_DESCCC|ZH_CODRESP|ZH_DESCRES|ZH_CHAMADO|ZH_MOTIVO|ZH_STATUS|ZH_DPSCM|"})
Local oStruSZI   := FWFormStruct(2, "SZI", {|cCampo| !AllTrim(cCampo)+"|"$ "ZI_CODPOST|ZI_LOCALID|ZI_DOC|ZI_DATADEV|ZI_PERDA|ZI_DPSMI|ZI_DPSEQ|ZI_DPSKIT|"+;
                                                                            "ZI_DPSSUB|ZI_DPSMC|ZI_DPSEQDV|"})
Local oModel     := FWLoadModel("MOVLOC")

oView := FWFormView():New()

oView:SetModel(oModel)

oView:AddField("VIEW_SZH", oStruSZH, "SZHMASTER")
oView:AddGrid("VIEW_SZI", oStruSZI, "SZIDETAIL")
oView:AddIncrementField("VIEW_SZI", "ZI_ITEM") 

oView:CreateHorizontalBox("CABEC", 30)
oView:CreateHorizontalBox("TOOLBAR", 10)
oView:CreateHorizontalBox("GRID", 60)

oView:AddOtherObject("BUTTONKIT", {|oPanel| ButtonKit(oPanel)})
    
oView:addUserButton("Paralisa / Reativa","MAGIC_BMP", {|| Paralisa()}, /*cToolTip*/, /*nShortCut*/, /*aOptions*/,/*lShowBar*/)

oView:SetCloseOnOk({|| .T.})
// oView:SetProperty("VIEW_SZH", BUTTONOK, .F.)

oView:SetOwnerView("VIEW_SZH", "CABEC")
oView:SetOwnerView("BUTTONKIT", "TOOLBAR")
oView:SetOwnerView("VIEW_SZI", "GRID")

Return(oView)

/*/{Protheus.doc} ButtonKit
Botão para disparo do Kit.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ButtonKit(oPanel)

Local oSay
Local oBtn
Local oFont      := TFont():New("Arial", /*uPar2*/, 16, /*uPar4*/, .T.)
Local oModel     := FWModelActive()
Local nOperation := oModel:GetOperation()

If nOperation == MODEL_OPERATION_INSERT
	oBtn := TButton():New(10, 10, "+ Kit", oPanel, {|| PesqKit()}, 80, 20,,,,.T.)
ElseIf nOperation == MODEL_OPERATION_UPDATE
	@ 010, 005 SAY oSay PROMPT;
	"*** Para Paralisar / reativar um equipamento, selecione um item patrimoniado, vá em outras ações -> Paralisa / Reativa";
	FONT oFont SIZE 600, 007 OF oPanel COLORS 0, 16777215 PIXEL
EndIf

Return

/*/{Protheus.doc} GetLineData
Carrega dados da linha amterior na linha atual.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function GetLineData()

Local oModel     := FWModelActive()
Local oGrid      := oModel:GetModel("SZIDETAIL")
Local nLinha     := oGrid:Length()
Local nLinAnt    := 0
Local nQuant     := 0
Local cCodKit    := ""
Local cISSI      := ""
Local cLocaliz   := ""
Local cNumSeq    := ""

If nLinha > 1
	nLinAnt := nLinha - 1 
	
	oGrid:GoLine(nLinAnt)
	
	cCodKit  := oGrid:GetValue("ZI_CODKIT")
	cISSI    := oGrid:GetValue("ZI_ISSI")
	cLocaliz := oGrid:GetValue("ZI_LOCALIZ")
	cNumSeq  := oGrid:GetValue("ZI_NUMSEQ")

	oGrid:GoLine(nLinha)

	nQuant   := oGrid:GetValue("ZI_QUANT")

	oGrid:SetValue("ZI_CODKIT", cCodKit)
	oGrid:SetValue("ZI_ISSI", cISSI)
	oGrid:SetValue("ZI_QUANT", If(nQuant == 0, 1, nQuant))
	oGrid:SetValue("ZI_LOCALIZ", cLocaliz)
	oGrid:SetValue("ZI_NUMSEQ", cNumSeq)
EndIf

Return(.T.)

/*/{Protheus.doc} SZILinOk
Valida linha de itens do movimento.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function MovTudoOk(oModel)

Local nX         := 0
Local oGrid      := oModel:GetModel("SZIDETAIL")
Local nOperation := oModel:GetOperation()
Local nLinhas    := oGrid:Length()
Local cItem      := ""
Local cPatrim    := ""
Local cProduto   := ""
Local nQuant     := ""
Local aSaveLines := FWSaveRows()
Local lRet       := .T.

If nOperation == MODEL_OPERATION_INSERT
	If nLinhas == 0
		Help(,, "SEMMOV",, "Preencha os equipamentos.", 1, 0)
		lRet := .F.
	EndIf

	For nX := 1 to nLinhas
		oGrid:GoLine(nX)

		If !oGrid:IsDeleted()
			cItem      := oGrid:GetValue("ZI_ITEM", nX, oModel)
			cPatrim    := oGrid:GetValue("ZI_PATRIM", nX, oModel)
			cProduto   := oGrid:GetValue("ZI_PRODUTO", nX, oModel)
			nQuant     := oGrid:GetValue("ZI_QUANT", nX, oModel)

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

Local nX, nI     := 0
Local nQtdItem   := 0
Local nOperation := oModel:GetOperation()
Local oModelSZH  := oModel:GetModel("SZHMASTER")
Local oModelSZI  := oModel:GetModel("SZIDETAIL")
Local lRetorno   := .T.
Local cCodPost   := oModelSZH:GetValue("ZH_CODPOST")
Local cLocalid   := oModelSZH:GetValue("ZH_LOCALID")
Local cDoc       := oModelSZH:GetValue("ZH_DOC")
Local cStatus    := oModelSZH:GetValue("ZH_STATUS")
Local cItem      := ""
Local cProduto   := ""
Local nQuant     := ""
Local cPatrim    := ""
Local cKit       := ""
Local cNumSeq    := ""
Local cISSI      := ""
Local lTemPat    := .F.

SZI->(DbSetOrder(1)) // Cód.Posto + Localidade + Documento + Item
SZJ->(DbSetOrder(3)) // Patrimônio
SZK->(DbSetOrder(1)) // Cód.Posto + Localidade + Kit + Patromônio
SZL->(DbSetOrder(1)) // Cód.Posto + Localidade + Kit
SZM->(DbSetOrder(1)) // Cód.Posto + Localidade + Documento + Item

If nOperation == MODEL_OPERATION_INSERT
	// Verifica se trata-se de um item não patrimoniado e trata para que a ISSI pertença a um
	// rádio válido e locado.
	For nI := 1 To oModelSZI:Length()
		oModelSZI:GoLine(nI)

		cPatrim   := oModelSZI:GetValue("ZI_PATRIM")

		If !Empty(cPatrim)
			lTemPat := .T.
			Exit
		EndIf
	Next nI

	If !lTemPat
		cISSI := oModelSZI:GetValue("ZI_ISSI", 1, oModel)

		If !Empty(cISSI)
			If !U_TemISSI(cISSI)
				Help( ,,"NAOTEMISSI",,"Não existe rádio locado com a ISSI informada, informe uma ISSI válida.", 1, 0 )
				Return(.F.)
			EndIf
		EndIf
	EndIf

	// Faz a gravação.
	For nI := 1 To oModelSZI:Length()
		oModelSZI:GoLine(nI)

		If !oModelSZI:IsDeleted()
			cItem     := oModelSZI:GetValue("ZI_ITEM")
			cProduto  := oModelSZI:GetValue("ZI_PRODUTO")
			nQuant    := oModelSZI:GetValue("ZI_QUANT")
			cPatrim   := oModelSZI:GetValue("ZI_PATRIM")
			cKit      := oModelSZI:GetValue("ZI_CODKIT")
			cNumSeq   := oModelSZI:GetValue("ZI_NUMSEQ")

			U_GravaEst(cCodPost, cLocalid, cProduto, "01", nQuant, "S")

			If !Empty(cPatrim)
				// Muda o status do patrimônio para locado.
				If SZJ->(DbSeek(xFilial("SZJ") + cPatrim))
					RecLock("SZJ", .F.)
					SZJ->ZJ_LOCADO := "S"
					MsUnlock()
				EndIf

				// Registra o valor da primeira locação caso ainda não tenha sido locado.
				If !SZK->(DbSeek(xFilial("SZK") + cCodPost + cLocalid + cKit + cPatrim))
					nValor := 0
					// Se não tem valor de referência do patrimôio anteior, consulta o valor vigente na tabela.
					If SZL->(DbSeek(xFilial("SZL") + cCodPost + cLocalid + cKit))
						While SZL->ZL_FILIAL == xFilial("SZL") .and.;
							SZL->ZL_CODPOST == cCodPost .and.;
							SZL->ZL_LOCALID == cLocalid .and.;
							SZL->ZL_CODKIT == cKit .and. !SZL->(EOF())
							
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
					SZK->ZK_CODKIT  := cKit
					SZK->ZK_ENTREGA := dDataBase
					SZK->ZK_PATRIM  := cPatrim
					SZK->ZK_VALOR   := nValor
					MsUnlock()
				EndIf
			EndIf
		EndIf
	Next nI
ElseIf nOperation == MODEL_OPERATION_UPDATE

ElseIf nOperation == MODEL_OPERATION_DELETE
	If cStatus == "A"
		If U_Temsubst(cDoc)
	        Help( ,,"SUSTNOTDEL",,"Esse movimento não pode ser excluído porque é um substituto de outro movimento. Exclua o movimento de substituição.", 1, 0 )
			Return(.F.)
		EndIf

		SZI->(DbSeek(xFilial("SZI") + cCodPost + cLocalid + cDoc))
		While SZI->ZI_FILIAL == xFilial("SZI") .and.;
			SZI->ZI_CODPOST == cCodPost .and.;
			SZI->ZI_LOCALID == cLocalid .and.;
			SZI->ZI_DOC == cDoc .and. !SZI->(EOF())
			// Estorna o estoque.
			U_GravaEst(cCodPost, cLocalid, SZI->ZI_PRODUTO, "01", SZI->ZI_QUANT, "E")

			// Estorna a locação do patrimônio.
			If !Empty(SZI->ZI_PATRIM)
				If SZJ->(DbSeek(xFilial("SZJ") + SZI->ZI_PATRIM))
					RecLock("SZJ", .F.)
					SZJ->ZJ_LOCADO := "N"
					MsUnlock()
				EndIf
			EndIf
			RecLock("SZI", .F.)
			SZI->(DbDelete())
			MsUnlock()
			SZI->(DbSkip())
		End
	ElseIf cStatus == "S" .or. cStatus == "R"
		// Procura o mobimento novo para estornar.
		SZI->(DbSetOrder(1)) // Cód. posto + Localidade + Documento + Item
		SZI->(DbSeek(xFilial("SZI") + cCodPost + cLocalid + cDoc))

		// Guarda a ISSI antiga para corrigir para a ISSI original os acessários
		// que por ventura tuveram a ISSI alterada na substituição do patrimônio.
		cISSISubs := AllTrim(SZI->ZI_ISSI)

		// Estorna o movimento novo.
		While SZI->ZI_FILIAL == xFilial("SZI") .and.;
			SZI->ZI_CODPOST == cCodPost .and.;
			SZI->ZI_LOCALID == cLocalid .and.;
			SZI->ZI_DOC == cDoc .and. !SZI->(EOF())

			// Verifica se tem patrimônio na substituição, para saber se deve
			// Corrigir a ISSI para o rádio origonal. Se a substituição foi 
			// apensa de acessários, não é necessário corrigir a ISSI, pois,
			// substituição somente de acessórios não muda a ISSI.
			If !Empty(SZI->ZI_PATRIM)
				lTemPat := .T.
			EndIf

			// Estorna o estoque.
			U_GravaEst(SZI->ZI_CODPOST, SZI->ZI_LOCALID, SZI->ZI_PRODUTO, "01", SZI->ZI_QUANT, "E")

			If !Empty(SZI->ZI_PATRIM)
				If SZJ->(DbSeek(xFilial("SZJ") + SZI->ZI_PATRIM))
					RecLock("SZJ", .F.)
					SZJ->ZJ_LOCADO := "N"
					MsUnlock()
				EndIf
			EndIf

			RecLock("SZI", .F.)
			SZI->(DbDelete())
			MsUnlock()
			SZI->(DbSkip())
		End

		// Estorna a substituição do item original.
		// Primeiro posiciona no registro original para obter a sequência correta.
		SZI->(DbSetOrder(3)) // Doc.substituto + Item
		SZI->(DbSeek(xFilial("SZI") + cDoc))
		cNumSeq  := SZI->ZI_NUMSEQ
		cDocSubs := SZI->ZI_DOCSUBS

		// Procura a sequência do kit original.
		SZI->(DbSetOrder(3)) // Doc.Substituto + Item
		SZI->(DbSeek(xFilial("SZI") + cDocSubs))

		While SZI->ZI_FILIAL == xFilial("SZI") .and.;
			SZI->ZI_NUMSEQ == cDocSubs .and. !SZI->(EOF())

			// Estorna o estoque.
			U_GravaEst(SZI->ZI_CODPOST, SZI->ZI_LOCALID, SZI->ZI_PRODUTO, If(SZI->ZI_STATUS == "S","02","03"), SZI->ZI_QUANT, "S")

			If !Empty(SZI->ZI_PATRIM)
				If SZJ->(DbSeek(xFilial("SZJ") + SZI->ZI_PATRIM))
					RecLock("SZJ", .F.)
					SZJ->ZJ_LOCADO := "S"
					MsUnlock()
				EndIf
			EndIf
			SZI->(DbSkip())
		End

		// Atualiza o status e limpa o documento substituto.
		cQuery := "UPDATE " + RetSQLName("SZI")
		cQuery += " SET ZI_STATUS = 'A', ZI_DOCSUBS = ''"
		cQuery += " WHERE "
		cQuery += "ZI_DOCSUBS = '" + cDoc + "' AND "
		cQuery += "D_E_L_E_T_ = ''"

		TCSQLExec(cQuery)

		// Ajusta acessários que tiveram a ISSI alterada para um novo patrimônio.
		// Busca a ISSI do patrimônio original, para usar quando o acessário
		// teve a ISSI alterada na troca do patrimônio.
		If lTemPat
			aPatrim := U_RetPatDoc(cNumSeq)

			// Grava a ISSI original caso o acessário teve a ISSI substituída.
			cQuery := "UPDATE " + RetSQLName("SZI")
			cQuery += " SET ZI_ISSI = '" + aPatrim[2] + "'"
			cQuery += " WHERE "
			cQuery += "ZI_ISSI = '" + cISSISubs + "' AND "
			cQuery += "ZI_STATUS = 'A' AND "
			cQuery += "D_E_L_E_T_ = ''"

			TCSQLExec(cQuery)
		EndIf
	ElseIf cStatus == "D"
		cDocDevol := SZH->ZH_DOC

		SZI->(DbSetOrder(3)) // Doc.Substituto + Item

		nQtdItem := oModelSZI:Length()

		// Começa ajustando os movimentos originais.
		For nX := 1 to nQtdItem
			oModelSZI:GoLine(nX)
		
			If SZI->(DbSeek(xFilial("SZI") + cDocDevol + oModelSZI:GetValue("ZI_ITEM", nX, oModel)))
				// Estorna o estoque.
				U_GravaEst(SZI->ZI_CODPOST, SZI->ZI_LOCALID, SZI->ZI_PRODUTO, "02", SZI->ZI_QUANT-SZI->ZI_PERDA, "S")

				// Estorna a perda no estoque.
				If SZI->ZI_PERDA > 0
					U_GravaEst(SZI->ZI_CODPOST, SZI->ZI_LOCALID, SZI->ZI_PRODUTO, "03", SZI->ZI_PERDA, "S")
				EndIf

				// Estorna a perda no registro de perdas.
				If SZM->(DbSeek(xFilial("SZM") + SZI->ZI_CODPOST + SZI->ZI_LOCALID + SZI->ZI_DOC + SZI->ZI_ITEM))
					RecLock("SZM", .F.)
					SZM->(DbDelete())
					MsUnlock()
				EndIf

				// Acerta o status do patrimônio
				If !Empty(SZI->ZI_PATRIM)
					If SZJ->(DbSeek(xFilial("SZJ") + SZI->ZI_PATRIM))
						RecLock("SZJ", .F.)
						SZJ->ZJ_LOCADO := "S"
						MsUnlock()
					EndIf
				EndIf

				// Atualiza o status do movimento para devolvido.
				RecLock("SZI", .F.)
				SZI->ZI_STATUS  := "A"
				SZI->ZI_DATADEV := CtoD("")
				SZI->ZI_PERDA   := 0
				SZI->ZI_DOCSUBS := ""
				MsUnlock()
			EndIf
		Next nX

		// Apaga o movimento da devolução.
		SZI->(DbSetOrder(1)) // Cód. posto + Localidade + Documento + Item
		SZI->(DbSeek(xFilial("SZI") + cCodPost + cLocalid + cDoc))
		While SZI->ZI_FILIAL == xFilial("SZI") .and.;
			SZI->ZI_CODPOST = cCodPost .and.;
			SZI->ZI_LOCALID == cLocalid .and.;
			SZI->ZI_DOC == cDoc .and. !SZI->(EOF())

			RecLock("SZI", .F.)
			SZI->(DbDelete())
			MsUnlock()

			SZI->(DbSkip())
		End

		RecLock("SZH", .F.)
		SZH->(DbDelete())
		MsUnlock()
	EndIf
EndIf

Begin Sequence
    If !(lRetorno := FWFormCommit(oModel))
        cLogMdl := cValToChar(oModel:GetErrorMessage()[4]) + ' - '
        cLogMdl += cValToChar(oModel:GetErrorMessage()[5]) + ' - '
        cLogMdl += cValToChar(oModel:GetErrorMessage()[6])
        Help( ,,"U_MOVLOC",,cLogMdl, 1, 0 )
        Break
    EndIf
End Sequence

Return(lRetorno)

/*/{Protheus.doc} PesqPatrim
Pesquisa o patrimônio e filtra a FWMBrose.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function PesqPatrim()

Local oMBrowse := FWmBrwActive()
Local oSay1, oSay2
Local oPatrim
Local oISSI
Local oButton1
Local oButton2
Local oDlg
Local nX       := 0
Local nOpcA    := 0
Local aDocs    := {}
Local cFiltro  := U_MBLocxUsr(1, "SZH")
Local cPatrim := Space(20)
Local cISSI   := Space(14)

DEFINE MSDIALOG oDlg TITLE "Pesquisa Patrimônio" FROM 000, 000  TO 160, 290 COLORS 0, 16777215 PIXEL

@ 005, 005 SAY oSay1 PROMPT "Patrimônio" SIZE 040, 007 OF oDlg COLORS 0, 16777215 PIXEL
@ 015, 005 MSGET oPatrim VAR cPatrim VALID(If(!Empty(cPatrim), (nOpcA := 1, oDlg:End()), nOpca := 0)) SIZE 135, 010 OF oDlg;
	COLORS 0, 16777215 PIXEL
@ 030, 005 SAY oSay2 PROMPT "ISSI" SIZE 040, 007 OF oDlg COLORS 0, 16777215 PIXEL
@ 040, 005 MSGET oISSI VAR cISSI VALID(If(!Empty(cISSI), (nOpcA := 1, oDlg:End()), nOpca := 0)) SIZE 135, 010 OF oDlg;
	COLORS 0, 16777215 PIXEL
@ 063, 064 BUTTON oButton1 PROMPT "Pesquisar" ACTION(nOpcA := 1, oDlg:End()) SIZE 037, 012 OF oDlg PIXEL
@ 063, 106 BUTTON oButton2 PROMPT "Cancelar" ACTION(nOpcA := 0, oDlg:End()) SIZE 037, 012 OF oDlg PIXEL

oPatrim:setFocus()

ACTIVATE MSDIALOG oDlg CENTERED

If nOpcA == 1 .and. !Empty(cPatrim)
	BeginSQL Alias "SZIQRY"
		SELECT
			ZI_DOC
		FROM
			%Table:SZI%
		WHERE
			ZI_PATRIM = %Exp:cPatrim% and
			%NotDel%
			ORDER BY ZI_DOC
	EndSQL

	While !SZIQRY->(EOF())
		aAdd(aDocs, SZIQRY->ZI_DOC)
		SZIQRY->(DbSkip())
	End
	SZIQRY->(DbCloseArea())

	If !Empty(aDocs)
		If !Empty(cFiltro)
			cFiltro += " .and. "
		EndIf

		For nX := 1 to Len(aDocs)
			cFiltro += "ZH_DOC = '" + aDocs[nX] + "' .or. "
		Next nX

		cFiltro := SubStr(cFiltro, 1, Len(cFiltro)-6)

		oMBrowse:SetFilterDefault(cFiltro)  
		oMBrowse:oBrowse:Refresh()
	EndIf
ElseIf nOpcA == 1 .and. !Empty(cISSI)
	BeginSQL Alias "SZIQRY"
		SELECT
			DISTINCT ZI_DOC
		FROM
			%Table:SZI%
		WHERE
			ZI_ISSI = %Exp:cISSI% and
			%NotDel%
			ORDER BY ZI_DOC
	EndSQL

	While !SZIQRY->(EOF())
		aAdd(aDocs, SZIQRY->ZI_DOC)
		SZIQRY->(DbSkip())
	End
	SZIQRY->(DbCloseArea())

	If !Empty(aDocs)
		If !Empty(cFiltro)
			cFiltro += " .and. "
		EndIf

		For nX := 1 to Len(aDocs)
			cFiltro += "ZH_DOC = '" + aDocs[nX] + "' .or. "
		Next nX

		cFiltro := SubStr(cFiltro, 1, Len(cFiltro)-6)

		oMBrowse:SetFilterDefault(cFiltro)  
		oMBrowse:oBrowse:Refresh()
	EndIf
EndIf

Return

/*/{Protheus.doc} LimpaFiltro
Limpa a pesquisa o patrimônio e o filtra.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function LimpaFiltro()

Local oMBrowse := FWmBrwActive()
Local cFiltro  := U_MBLocxUsr(1, "SZH")

oMBrowse:SetFilterDefault(cFiltro)  
oMBrowse:oBrowse:Refresh()

Return

/*/{Protheus.doc} PesqKit
Pesquisa os kits para carregar no grid.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function PesqKit()

Local oSay1, oSay2, oSay3
Local oGet1, oGet2, oGet3
Local oButton1, oButton2
Local oDlg
Local oModel    := FWModelActive()
Local oModelSZH := oModel:GetModel("SZHMASTER")
Local oGrid     := oModel:GetModel("SZIDETAIL")
Local cCodPost  := oModelSZH:GetValue("ZH_CODPOST")
Local cLocalid  := oModelSZH:GetValue("ZH_LOCALID")
Local cKit      := Space(6)
Local cISSI     := Space(14)
Local cISSIAux  := Space(14)
Local cLocaliz  := Space(40)

If Empty(cCodPost) .or. Empty(cLocalid)
	MsgInfo("Digite o código do posto e a localidade.", "Atenção")
	Return
EndIf

If !Empty(oGrid:GetValue("ZI_ISSI", 1, oModel))
	cISSIAux := oGrid:GetValue("ZI_ISSI", 1, oModel)
EndIf

DEFINE MSDIALOG oDlg TITLE "Pesquisa de Kits" FROM 000, 000  TO 220, 500 COLORS 0, 16777215 PIXEL

@ 005, 005 SAY oSay1 PROMPT "Kit" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
@ 014, 005 MSGET oGet1 VAR cKit VALID(cISSI := cISSIAux) SIZE 060, 010 OF oDlg COLORS 0, 16777215 F3 "Z20" PIXEL
@ 030, 005 SAY oSay2 PROMPT "ISSI" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
@ 056, 005 SAY oSay3 PROMPT "Localização" SIZE 035, 007 OF oDlg COLORS 0, 16777215 PIXEL
@ 039, 005 MSGET oGet2 VAR cISSI SIZE 060, 010 OF oDlg COLORS 0, 16777215 PIXEL
@ 065, 005 MSGET oGet3 VAR cLocaliz SIZE 237, 010 OF oDlg COLORS 0, 16777215 PIXEL


@ 094, 163 BUTTON oButton1 PROMPT "Confirmar" ACTION(LoadKit(cKit, cISSI, cLocaliz), oDlg:End()) SIZE 037, 012 OF oDlg PIXEL
@ 094, 205 BUTTON oButton2 PROMPT "Cancelar" ACTION(oDlg:End()) SIZE 037, 012 OF oDlg PIXEL

ACTIVATE MSDIALOG oDlg CENTERED

Return

/*/{Protheus.doc} LoadKit
Carrega os itens do kit no grid.

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
Local oGrid     := oModel:GetModel('SZIDETAIL')
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

		oGrid:SetValue("ZI_STATUS" , "A")
		oGrid:SetValue("ZI_ITEM"   , Soma1(cItem))
		oGrid:SetValue("ZI_PRODUTO", cProduto)
		oGrid:SetValue("ZI_PATRIM" , Space(10))
		oGrid:SetValue("ZI_NUMSER" , Space(25))
		oGrid:SetValue("ZI_ISSI"   , cISSI)
		oGrid:SetValue("ZI_CODKIT" , cKit)
		oGrid:SetValue("ZI_QUANT"  , Z21->Z21_QTD)
		oGrid:SetValue("ZI_DATAMOV", dDataBase)
		oGrid:SetValue("ZI_LOCALIZ", cLocaliz)
		oGrid:SetValue("ZI_DESCRI" , SB1->B1_DESC)
		oGrid:SetValue("ZI_NUMSEQ" , cNumSeq)

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

/*/{Protheus.doc} Paralisa
Paralisa / reativa a cobrança do documento de locação.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/

Static Function Paralisa()

Local oModel    := FWModelActive()
Local oModelSZH := oModel:GetModel("SZHMASTER")
Local oGrid     := oModel:GetModel('SZIDETAIL')
Local nLinha    := oGrid:GetLine()
Local cCodPost  := oModelSZH:GetValue("ZH_CODPOST")
Local cLocalid  := oModelSZH:GetValue("ZH_LOCALID")
Local cDoc      := oModelSZH:GetValue("ZH_DOC")
Local cStatus   := oGrid:GetValue("ZI_STATUS", nLinha, oModel)
Local cItem     := oGrid:GetValue("ZI_ITEM", nLinha, oModel) 
Local cPatrim   := oGrid:GetValue("ZI_PATRIM", nLinha, oModel)

SZI->(DbSetOrder(1)) // Cód.Posto + Localidade + Documento + Item
SZW->(DbSetorder(1)) // Documento + Patrimônio

If Empty(cPatrim)
	MsgInfo("Esse equipamento não é um patrimônio.", "Atenção")
	Return
EndIf

If !cStatus $ "A/P"
	MsgInfo("Esse equipamento não está ativo ou pausado.", "Atenção")
	Return
EndIf

If SZI->(DbSeek(xFilial("SZI") + cCodPost +  cLocalid + cDoc + cItem))
	If cStatus == "A"
		If MsgYesNo("Deseja pausar o patrimônio? Se confirmar esse patrimônio não será considerado nas medições futuras.", "Atenção")
			// Grava o movimento.
			If !SZW->(DbSeek(xFilial("SZW") + cDoc + cPatrim))
				RecLock("SZW", .T.)
				SZW->ZW_FILIAL  := xFilial("SZW")
				SZW->ZW_DOC     := cDoc
				SZW->ZW_PATRIM  := cPatrim
				SZW->ZW_DTPAUSA := dDataBase
				SZW->ZW_STATUS  := "P"
				MSUnlock()
			Else
				If !Empty(SZW->ZW_DTATIVA)
					If dDataBase - SZW->ZW_DTATIVA <= 30
						MsgInfo("Esse equipamento foi pausado há menos de 30 dias e não poderá ser pausado novamente até que esse prazo expire.", "Atenção")
						Return
					EndIf
				EndIf

				RecLock("SZW", .F.)
				SZW->ZW_DTPAUSA := dDataBase
				SZW->ZW_DTATIVA := CtoD("")
				MSUnlock()
			EndIf

			// Muda o status do patrimônio.
			RecLock("SZI", .F.)
			SZI->ZI_STATUS := "P"
			MsUnlock()

			oGrid:SetValue("ZI_STATUS", "P")
		EndIf
	ElseIf cStatus == "P"
		If MsgYesNo("Deseja reativar o patrimônio? Se confirmar esse patrimônio será considerado nas medições futuras.", "Atenção")
			// Grava o movimento.
			If SZW->(DbSeek(xFilial("SZW") + cDoc + cPatrim))
				RecLock("SZW", .F.)
				SZW->ZW_DTATIVA := dDataBase
				MSUnlock()
			EndIf

			// Muda o status do patrimônio.
			RecLock("SZI", .F.)
			SZI->ZI_STATUS := "A"
			MsUnlock()
		EndIf
		
		oGrid:SetValue("ZI_STATUS", "A")
	EndIf
EndIf

Return

/*/{Protheus.doc} MVCEnd
Utilitário para fechar o formulário MVC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function MVCEnd()

Local nAtual
Local bAction := {|| }
Private nAtuPvt
Private oPai       := GetWndDefault()
Private aControles := oPai:aControls

For nAtual := 1 To Len(aControles)
    nAtuPvt := nAtual

    If Type("aControles[nAtuPvt]:bAction") != "U"
        If Upper(Alltrim(aControles[nAtuPvt]:cCaption)) == "FECHAR"

            bAction := aControles[nAtuPvt]:bAction
            eVal(bAction)
        EndIf
    EndIf
Next

Return
