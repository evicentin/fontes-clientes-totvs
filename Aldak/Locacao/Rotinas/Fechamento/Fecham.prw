#Include "totvs.ch"
#Include "fwmvcdef.ch"

/*/{Protheus.doc} Fecham
Cadastro de Centros de Custos.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function Fecham()

Local oBrowse

oBrowse := FWMBrowse():New()
oBrowse:SetAlias("SZP")
oBrowse:SetDescription("Fechamento")

oBrowse:SetFilterDefault(U_MBLocxUsr(1, "SZP"))

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

ADD OPTION aRotina TITLE "Visualizar"       ACTION "VIEWDEF.FECHAM" OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE "Gerar Fechamento" ACTION "U_GeraFecha()"  OPERATION 3 ACCESS 0
ADD OPTION aRotina TITLE "Alterar"          ACTION "VIEWDEF.FECHAM" OPERATION 4 ACCESS 0
ADD OPTION aRotina TITLE "Estornar"         ACTION "VIEWDEF.FECHAM" OPERATION 5 ACCESS 0

Return(aRotina)

/*/{Protheus.doc} MODELDEF
Modelo de Dados do MVC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ModelDef()

Local oModel
Local oStruSZP := FWFormStruct(1, "SZP")
Local oStruSZQ := FWFormStruct(1, "SZQ")
Local oStruSZX := FWFormStruct(1, "SZX")

oModel := MPFormModel():New("FECHAMM", /*bPreValidacao*/, /*bPosValidacao*/, , /*bCancel*/ )

oModel:AddFields("SZPMASTER",, oStruSZP)

oModel:AddGrid("SZQDETAIL", "SZPMASTER", oStruSZQ)
oModel:AddGrid("SZXDETAIL", "SZPMASTER", oStruSZX)

oModel:SetRelation("SZQDETAIL", {{"ZQ_FILIAL", "xFilial('SZQ')"}, {"ZQ_DOC", "ZP_DOC"}}, SZQ->(IndexKey(1)))
oModel:SetRelation("SZXDETAIL", {{"ZX_FILIAL", "xFilial('SZX')"}, {"ZX_DOC", "ZP_DOC"}}, SZX->(IndexKey(1)))

oModel:SetPrimaryKey({})

oModel:SetDescription("Fechamento")
oModel:GetModel("SZPMASTER"):SetDescription("Dados do Documento de Fechamento")
oModel:GetModel("SZQDETAIL"):SetDescription("Dados dos itens de Fechamento")
oModel:GetModel("SZXDETAIL"):SetDescription("Dados dos itens de Rateio")

Return(oModel)

/*/{Protheus.doc} VIEWDEF
View do MVC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ViewDef()

Local oView
Local oStruSZP   := FWFormStruct(2, "SZP")
Local oStruSZQ   := FWFormStruct(2, "SZQ", {|x| AllTrim(x) <> "ZQ_DOC"})
Local oStruSZX   := FWFormStruct(2, "SZX", {|x| AllTrim(x) <> "ZX_DOC"})
Local oModel     := FWLoadModel("FECHAM")

oView := FWFormView():New()

oView:SetModel(oModel)

oView:AddField("VIEW_SZP", oStruSZP, "SZPMASTER")
oView:AddGrid("VIEW_SZQ", oStruSZQ, "SZQDETAIL")
oView:AddGrid("VIEW_SZX", oStruSZX, "SZXDETAIL")

oView:SetCloseOnOk({|| .T.})

oView:CreateHorizontalBox("CABEC", 30)
oView:CreateHorizontalBox("DET", 70)

// Cria Folder na view
oView:CreateFolder("PASTAS", "DET")

// Cria pastas nas folders
oView:AddSheet("PASTAS", "ABA01", "Itens")
oView:AddSheet("PASTAS", "ABA02", "Rateios")

oView:CreateHorizontalBox("ITENS", 100,,, "PASTAS", "ABA01")
oView:CreateHorizontalBox("RATEIO", 100,,, "PASTAS", "ABA02")

oView:SetOwnerView("VIEW_SZP", "CABEC")
oView:SetOwnerView("VIEW_SZQ", "ITENS")
oView:SetOwnerView("VIEW_SZX", "RATEIO")

Return(oview)

/*/{Protheus.doc} GeraFecha
Geração do fechamento.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function GeraFecha()

Local cMesFecha  := ""
Local cAnoFecha  := ""
Local dDataIni   := Ctod("")
Local dDataFim   := Ctod("")
Local dDataCorte := CtoD("")
Local dData15Ant := CtoD("")
Local dDataFimMe := CtoD("")

SZ0->(DbSetOrder(1)) // Cód. Posto + Resposnável
SZ1->(DbSetOrder(1)) // Cód. Posto
SZ2->(DbSetOrder(2)) // Localidade
SZH->(DbSetOrder(2)) // Documento 
SZK->(DbSetOrder(1)) // Cód. Posto + Localidade + Kit + Patrimônio
SZL->(DbSetOrder(1)) // Cód. Posto + Localidade + Kit
SZP->(DbSetOrder(2)) // Cód. Posto + Período
Z20->(DbSetOrder(1)) // Kit

If !Pergunte("GERAFECHAM", .T.)
	Return
EndIf

If !U_ValidPer(mv_par02)
	Return
EndIf

cMesFecha := StrZero(Val(SubStr(mv_par02, 1, 2)))
cAnoFecha := SubStr(mv_par02, 3, 4)

If SZ1->(DbSeek(xFilial("SZ1") + mv_par01))
	If Empty(SZ1->Z1_DIAFECH) .or. Empty(SZ1->Z1_DIACORT)
		MsgInfo("Data de fechamento ou data de corte não parametrizados, parametrize-os no cadastro do posto avançado.", "Atenção")
		Return
	EndIf

	If Val(cMesFecha) > 1
		cMesIni := StrZero(Val(cMesFecha)-1, 2)
		cAnoIni := cAnoFecha
		cMesFim := cMesFecha
		cAnoFim := cAnoFecha
	Else
		cMesIni := "12"
		cAnoIni := AllTrim(Str(Val(cAnoFecha)-1))
		cMesFim := cMesFecha
		cAnoFim := cAnoFecha
	EndIf

	// Medição mês 07:
	// 01/06 a 30/06 Ativos (que a entrega aconteceu em qualquer data até 30/06)
	// Devolução: 16/06 a 15/07.

	dDataIni   := CtoD(StrZero(Val(SZ1->Z1_DIAFECH)+1, 2) + "/" + cMesIni + "/" + cAnoIni)
	dDataFim   := CtoD(StrZero(Val(SZ1->Z1_DIAFECH), 2) + "/" + cMesFim + "/" + cAnoFim)
	dDataCorte := CtoD(StrZero(Val(SZ1->Z1_DIACORT), 2) + "/" + cMesFim + "/" + cAnoFim)
	dData15Ant := CtoD(StrZero(Val(SZ1->Z1_DIACORT), 2) + "/" + cMesIni + "/" + cAnoIni)
	dDataFimMe := LastDay(dDataIni)
Else
	MsgInfo("Posto avançado não encontrado.", "Atenção")
	Return
EndIf

If SZP->(DbSeek(xFilial("SZP") + mv_par01 + mv_par02))
	MsgInfo("Já existe fechamento nesse período.", "Atenção")
	Return
EndIf

MsgRun("Aguarde, carregando movimentos...",, {|| ProcFecha(dDataIni, dDataFim, dDataCorte, dData15Ant, dDataFimMe)})

Return

/*/{Protheus.doc} ValidPer
Valida parâmetros das perguntas.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function ValidPer(cPeriodo)

Local lRet := .T.
Local cMes := AllTrim(SubStr(cPeriodo, 1, 2))
Local cAno := SubStr(cPeriodo, 3, 4)

If Len(cPeriodo) < 6
	MsgInfo("Período inválido, o formato deve ser mm/aaaa, onde, mm -> mês e aaaa -> ano, ex.: (01/2026).", "Atenção")
	lRet := .f.
EndIf

If !IsDigit(cMes) .or. !IsDigit(cAno)
	MsgInfo("Período inválido.", "Atenção")
	lRet := .f.
EndIf

if Val(cMes) < 1 .or. Val(cMes) > 12 .or. Val(cAno) < 1900 .or. Val(cAno) > 2040
	MsgInfo("Período inválido.", "Atenção")
	lRet := .f.
EndIf

Return(lRet)

/*/{Protheus.doc} ProcFecha
Processamento do fechamento.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ProcFecha(dDataIni, dDataFim, dDataCorte, dData15Ant, dDataFimMe)

Local nValor     := 0
Local cDoc       := ""
Local cCodResp   := ""
Local cNome      := ""
Local cDescKit   := ""
Local cPatOri    := ""
Local cProjeto   := ""
Local cItQQP     := ""
Local cLocalid   := ""
Local cItem      := "000"
Local aPatOri    := {}
Local dEntOri    := CtoD("")
Local dPriEnt    := CtoD("")
Local dEnt1      := CtoD("")
Local dEnt2      := CtoD("")

SZ0->(DbSetOrder(1)) // Cód. Posto + Resposnável
SZ1->(DbSetOrder(1)) // Cód. Posto
SZ8->(DbSetOrder(1)) // Cód. Posto + Cód. Kit
SZI->(DbSetOrder(3)) // Doc. substituto
SZK->(DbSetOrder(2)) // Patrimônio
SZW->(DbSetOrder(1)) // Documemto + Patrimônio
Z42->(DbSetOrder(4)) // Projeto + Num.QQP + Item QQP

// A primeira query busca todos os patrimônios ativos e pausados até a data limite do fechamento.
// A segunda query traz os devolvidos na última quinzena antes do fechamento atual, para serem cobrados.
BeginSQL Alias "SZIQRY"
	SELECT
		ZI_DOC, ZI_CODPOST, ZI_LOCALID, ZI_DOC, ZI_STATUS, ZI_PRODUTO, ZI_DESCRI, ZI_PATRIM, ZI_ISSI, ZI_CODKIT, ZI_QUANT, ZI_LOCALIZ, 
		ZI_DATAMOV, ZI_DATADEV, ZI_DESCRI, ZH_CC, ZH_STATUS
	FROM
		%Table:SZI% SZI
		INNER JOIN %Table:SZH% SZH ON ZH_DOC = ZI_DOC
		INNER JOIN %Table:SZ1% SZ1 ON Z1_CODPOST = ZH_CODPOST
	WHERE
		ZI_FILIAL = %xFilial:SZI% AND
		ZH_FILIAL = %xFilial:SZH% AND
		Z1_FILIAL = %xFilial:SZ1% AND
		ZH_CODPOST = %Exp:mv_par01% AND
		ZH_LOCALID BETWEEN %Exp:mv_par03% AND %Exp:mv_par04% AND
		ZI_STATUS IN ('A','P') AND
		ZI_PATRIM <> '' AND
		ZI_DATAMOV < %Exp:DtoS(dDataFim)% AND
		SZI.%NotDel% AND
		SZH.%NotDel% AND
		SZ1.%NotDel%

		UNION ALL

	SELECT
		ZI_DOC, ZI_CODPOST, ZI_LOCALID, ZI_DOC, ZI_STATUS, ZI_PRODUTO, ZI_DESCRI, ZI_PATRIM, ZI_ISSI, ZI_CODKIT, ZI_QUANT, ZI_LOCALIZ, 
		ZI_DATAMOV, ZI_DATADEV, ZI_DESCRI, ZH_CC, ZH_STATUS
	FROM
		SZI010 SZI
		INNER JOIN SZH010 SZH ON ZH_DOC = ZI_DOC
		INNER JOIN SZ1010 SZ1 ON Z1_CODPOST = ZH_CODPOST
	WHERE
		ZI_FILIAL = %xFilial:SZI% AND
		ZH_FILIAL = %xFilial:SZH% AND
		Z1_FILIAL = %xFilial:SZ1% AND
		ZH_CODPOST = %Exp:mv_par01% AND
		ZH_LOCALID BETWEEN %Exp:mv_par03% AND %Exp:mv_par04% AND
		ZI_STATUS = 'D' AND
		ZI_PATRIM <> '' AND
		ZI_DATAMOV BETWEEN %Exp:DtoS(dDataIni)% AND %Exp:DtoS(dDataFim)% AND
		SZI.%NotDel% AND
		SZH.%NotDel% AND
		SZ1.%NotDel%
	ORDER BY ZI_LOCALID, ZH_CC, ZI_PRODUTO, ZI_PATRIM
EndSQL

If !SZIQRY->(EOF())
	BeginTran()

	cDoc := GetSXENum("SZP", "ZP_DOC")

	RecLock("SZP", .T.)
	SZP->ZP_FILIAL  := xFilial("SZP")
	SZP->ZP_DOC     := cDoc
	SZP->ZP_CODPOST := SZIQRY->ZI_CODPOST
	SZP->ZP_LOCALID := If(mv_par03 <> mv_par04 .and. !Empty(mv_par04), mv_par03 + " a " + mv_par04, mv_par03)
	SZP->ZP_PERIODO := SubStr(mv_par02, 1, 2) + "/" + SubStr(mv_par02, 3, 4)
	SZP->ZP_DTFECHA := dDataBase
	MsUnlock()

	// Busca o projeto e número da QQP para buscar os valores dos itens.
	If SZ1->(DbSeek(xFilial("SZ1") + SZIQRY->ZI_CODPOST))
		cProjeto := SZ1->Z1_PROJET
		cNumQQP  := U_RetLastQQP(cProjeto)
	EndIf

	While !SZIQRY->(EOF())
		cItem    := Soma1(cItem)
		cCodResp := ""
		cNome    := ""
		cDescKit := ""

		If Empty(cLocalid) .or. SZIQRY->ZI_LOCALID <> SZ2->Z2_LOCALID
			SZ2->(DbSeek(xFilial("SZ2") + SZIQRY->ZI_LOCALID))
			cLocalid := SZ2->Z2_LOCALID
		EndIf

		// Busca dados do responsável.
		If SZH->(DbSeek(xFilial("SZH") + SZIQRY->ZI_DOC))
			If SZ0->(DbSeek(xFilial("SZ0") + SZIQRY->ZI_CODPOST + SZH->ZH_CODRESP))
				cCodResp := SZ0->Z0_CODRESP
				cNome    := SZ0->Z0_NOME
			EndIf
		EndIf
		
		// Busca dados do kit.
		If Z20->(DbSeek(xFilial("Z20") + SZIQRY->ZI_CODKIT))
			cDescKit := Z20->Z20_DESCR
		EndIf

		// Usado somente para debug.
		// If AllTrim(SZIQRY->ZI_PATRIM) $ "MT0007177/05NA47548/MT0008266/MT0005775/MT0008673/MT0005606"
		// 	Alert(SZIQRY->ZI_PATRIM)
		// EndIf

		// Buscamos o patrimônio a ser pesquisado. Caso tenha sido substituído, temos que buscar o 
		// patrimônio do documento original para obtermos o valor correto.
		If SZIQRY->ZH_STATUS == "A" // Ativo (Entrega).
			cPatOri := SZIQRY->ZI_PATRIM
			dEntOri := StoD(SZIQRY->ZI_DATAMOV)
		ElseIf SZIQRY->ZH_STATUS $ "S/D" // Substituição / Devolução
			aPatOri := U_PatrimOri(SZIQRY->ZI_DOC)

			If !Empty(aPatOri)
				cPatOri := aPatOri[1]
				dEntOri := aPatOri[2]
			Else
				cPatOri := SZIQRY->ZI_PATRIM
				dEntOri := StoD(SZIQRY->ZI_DATAMOV)
			EndIf
		EndIf

		// Valor a ser apropriado.
		nValor := 0

		// Buscamos a informação da primeira entrega. A regra é, a data da primeira entrega mais antiga entre os 
		// documentos de entrega e o a substitução deve prevalecer para calcular o valor.
		dPriEnt := CtoD("")
		If SZIQRY->ZI_PATRIM <> cPatOri
			// Pega aprimeira entrega do documento substituído / devolvido.
			If SZK->(DbSeek(xFilial("SZK") + SZIQRY->ZI_PATRIM)) 
				dEnt1 := SZK->ZK_ENTREGA
			EndIf

			If SZK->(DbSeek(xFilial("SZK") + cPatOri)) 
				dEnt2 := SZK->ZK_ENTREGA
			EndIf

			If !Empty(dEnt1) .and. !Empty(dEnt2)
				If dEnt1 < dEnt2
					dPriEnt := dEnt1
				Else
					dPriEnt := dEnt2
				EndIf
			Else
				dPriEnt := SZIQRY->ZI_DATAMOV
			EndIf
		Else
			// failover... Se algo deu errado nos cadastros, considera a entrega com a data do documento original.
			If SZK->(DbSeek(xFilial("SZK") + cPatOri)) 
				dPriEnt := SZK->ZK_ENTREGA
			EndIf
		EndIf

		// Verifica se a entrega ocorreu entre a quinzena anterior à medição e a data de corte e se é
		// primeira entrega, nesse caso cobra-se apenas a ativaçao.
		If dEntOri >= dData15Ant .and. dEntOri < dDataCorte-1 .and. dEntOri == dPriEnt .and. SZIQRY->ZH_STATUS == "A"
			// Busca o valor de ativação na tabela de QQP.
			If SZ8->(DbSeek(xFilial("SZ8") + SZIQRY->ZI_CODPOST + SZIQRY->ZI_CODKIT))
				If Z42->(DbSeek(xFilial("Z42") + cProjeto + cNumQQP + SZ8->Z8_ITTXATV))
					nValor := Z42->Z42_VLUNI
				EndIf
			EndIf
		Else
			// Movimentos dentro do período de medição que não são primeira entrega, cobra-se a medição.
			If SZ8->(DbSeek(xFilial("SZ8") + SZIQRY->ZI_CODPOST + SZIQRY->ZI_CODKIT))
				// Busca a faixa de valores correta.
				If dPriEnt <= SZ8->Z8_DTLIM01
					cItQQP := SZ8->Z8_ITQQP01
				ElseIf dPriEnt <= SZ8->Z8_DTLIM02
					cItQQP := SZ8->Z8_ITQQP02
				Else
					cItQQP := SZ8->Z8_ITQQP03
				EndIf

				// Busca o valor na tabela de QQP.
				If Z42->(DbSeek(xFilial("Z42") + cProjeto + cNumQQP + cItQQP))
					nValor := Z42->Z42_VLUNI
				EndIf
			EndIf

			// Patrimônios pausados não gera cobrança. Porém temos que analisar se a pausa está fora ou dentro
			// do período de medição. Pausado depois doperíodo de medição, deve cobrar.
			If SZIQRY->ZI_STATUS $ "P/D"
				cDocOri := SZIQRY->ZI_DOC

				// Devolução precisa buscar o documento de origem, pois, esse é o que consta no registro de patrimônio
				// pausado.
				If SZIQRY->ZI_STATUS == "D"
					If SZI->(DbSeek(xFilial("SZI") + SZIQRY->ZI_DOC))
						cDocOri := SZI->ZI_DOC
					EndIf
				EndIf

				If SZW->(DbSeek(xFilial("SZW") + cDocOri + SZIQRY->ZI_PATRIM))
					If SZW->ZW_DTPAUSA <= dDataFimMe .and. SZW->ZW_STATUS == "P"
						nValor := 0
					EndIf
				EndIf
			EndIf

			// Se a data de entrega for maior do que a data de corte, não cobra locação.
			If dEntOri >= dDataCorte
				SZIQRY->(DbSkip())
				Loop
			EndIf
		EndIf

		RecLock("SZQ", .T.)
		SZQ->ZQ_FILIAL  := xFilial("SZQ")
		SZQ->ZQ_DOC     := cDoc
		SZQ->ZQ_STATUS  := If(SZIQRY->ZI_STATUS=="P", "P", "N")
		SZQ->ZQ_ITEM    := cItem
		SZQ->ZQ_LOCALID := SZIQRY->ZI_LOCALID
		SZQ->ZQ_DESCLOC := SZ2->Z2_DESCRI
		SZQ->ZQ_CC 		:= SZIQRY->ZH_CC
		SZQ->ZQ_KIT     := SZIQRY->ZI_CODKIT
		SZQ->ZQ_DTENT   := dPriEnt
		SZQ->ZQ_DESCKIT := cDescKit
		SZQ->ZQ_VALOR   := nValor
		SZQ->ZQ_QUANT   := SZIQRY->ZI_QUANT
		SZQ->ZQ_PRODUTO := SZIQRY->ZI_PRODUTO
		SZQ->ZQ_DESCPRO := SZIQRY->ZI_DESCRI
		SZQ->ZQ_DOCENT  := SZIQRY->ZI_DOC
		SZQ->ZQ_CODRESP := cCodResp
		SZQ->ZQ_NOME    := cNome
		SZQ->ZQ_PATRIM  := SZIQRY->ZI_PATRIM
		SZQ->ZQ_ISSI    := SZIQRY->ZI_ISSI
		MsUnlock()
		SZIQRY->(DbSkip())
	End
	SZIQRY->(DbCloseArea())

	ConfirmSX8()

	MsgRun("Aguarde, carregando rateios...",, {|| ProcRateio(cProjeto, dDataIni, dDataFim, dDataCorte, cDoc)})

	EndTran()
Else
	MsgInfo("Sem movimentos para os parâmetros informados.", "Atenção")
	Return
EndIf

Return

Static Function ProcRateio(cProjeto, dDataIni, dDataFim, dDataCorte, cDoc)

// Agrupa os patrimônios por centro de custo para poder distribuir o rateio proporcinal.
BeginSQL Alias "SZQQRY"
	SELECT 
		ZQ_CC, Z5_DESCRI, COUNT(ZQ_PATRIM) AS ZQ_TOTPAT
	FROM
		%Table:SZQ% SZQ
		INNER JOIN %Table:SZ5% SZ5 ON Z5_CC = ZQ_CC
	WHERE
		ZQ_FILIAL = %xFilial:SZQ% 
		AND Z5_FILIAL = %xFilial:SZ5% 
		AND ZQ_DOC = %Exp:cDoc% 
		AND SZ5.%NotDel%
		AND SZQ.%NotDel%
	GROUP BY ZQ_CC, Z5_DESCRI
EndSQL

// Processa os itens a serem rateados.
BeginSQL Alias "SZEQRY"
	SELECT 
		ZS_LOCALID, ZE_ITEM, ZE_DESCRI, ZE_QUANT, Z42_VLUNI, ZO_CC, ZO_DESCCC, ZO_PERC, ZS_ITEM, COUNT(ZQ_PATRIM) AS ZQ_TOTPAT
	FROM 
		%Table:SZE% SZE
		INNER JOIN %Table:SZN% SZN ON ZE_CODIGO = ZN_CODIGO
		INNER JOIN %Table:Z43% Z43 ON Z43_PROJET = ZN_PROJETO
		LEFT JOIN %Table:Z42% Z42 ON Z43_NUMQQP = Z42_NUMQQP AND Z42_ITQQP = ZE_ITEM
		LEFT JOIN %Table:SZO% SZO ON ZO_CODIGO = ZE_CODIGO AND ZO_ITEM = ZE_ITREC
		LEFT JOIN %Table:SZS% SZS ON ZS_CODIGO = ZE_CODIGO AND ZS_ITEM = ZE_ITREC 
		INNER JOIN %Table:SZQ% SZQ ON ZQ_LOCALID = ZS_LOCALID
	WHERE
		ZE_FILIAL = %xFilial:SZE%
		AND ZN_FILIAL = %xFilial:SZN%
		AND Z43_FILIAL = %xFilial:Z43%
		AND Z42_FILIAL = %xFilial:Z42%
		AND ZO_FILIAL = %xFilial:SZO%
		AND ZS_FILIAL = %xFilial:SZS%
		AND ZQ_FILIAL = %xFilial:SZQ%

		AND ZN_PROJETO = %Exp:cProjeto%
		AND Z43_DTINI <= %Exp:DtoS(dDataIni)%
		AND Z43_DTFIM >= %Exp:DtoS(dDataFim)%
		AND ZE_DATAINI <= %Exp:DtoS(dDataCorte)%
		AND ZE_DATAFIM >= %Exp:DtoS(dDataIni)%

		AND SZE.%NotDel%
		AND SZN.%NotDel%
		AND Z43.%NotDel%
		AND Z42.%NotDel%
		AND SZO.%NotDel%
		AND SZS.%NotDel%
		AND SZQ.%NotDel%
	GROUP BY ZS_LOCALID, ZE_ITEM, ZE_DESCRI, ZE_QUANT, Z42_VLUNI, ZO_CC, ZO_DESCCC, ZO_PERC, ZS_ITEM

	SELECT
		ZS_LOCALID, ZE_ITEM, ZE_DESCRI, ZE_QUANT, Z42_VLUNI, ZO_CC, ZO_DESCCC, ZO_PERC, ZS_ITEM, COUNT(ZQ_PATRIM) AS ZQ_PATRIM
	FROM
		%Table:SZE% SZE
		INNER JOIN %Table:SZN% SZN ON ZE_CODIGO = ZN_CODIGO
		INNER JOIN %Table:Z43% Z43 ON Z43_PROJET = ZN_PROJETO
		LEFT JOIN %Table:Z42% Z42 ON Z43_NUMQQP = Z42_NUMQQP AND Z42_ITQQP = ZE_ITEM
		LEFT JOIN %Table:SZO% SZO ON ZO_CODIGO = ZE_CODIGO AND ZO_ITEM = ZE_ITREC
		LEFT JOIN %Table:SZS% SZS ON ZS_CODIGO = ZE_CODIGO AND ZS_ITEM = ZE_ITREC 
		INNER JOIN %Table:SZQ% SZQ ON ZQ_LOCALID = ZS_LOCALID
	WHERE 
		ZE_FILIAL = %xFilial:SZE%
		AND ZN_FILIAL = %xFilial:SZN%
		AND Z43_FILIAL = %xFilial:Z43%
		AND Z42_FILIAL = %xFilial:Z42%
		AND ZO_FILIAL = %xFilial:SZO%
		AND ZS_FILIAL = %xFilial:SZS%
		AND ZQ_FILIAL = %xFilial:SZQ%

		AND ZN_PROJETO = %Exp:cProjeto%
		AND Z43_DTINI <= %Exp:DtoS(dDataIni)%
		AND Z43_DTFIM >= %Exp:DtoS(dDataFim)%
		AND ZE_DTEXEC < %Exp:DtoS(dDataCorte)%
		AND ZE_DTEXEC >= %Exp:DtoS(dDataIni)%

		AND SZE.%NotDel%
		AND SZN.%NotDel%
		AND Z43.%NotDel%
		AND Z42.%NotDel%
		AND SZO.%NotDel%
		AND SZS.%NotDel%
		AND SZQ.%NotDel%
	GROUP BY ZS_LOCALID, ZE_ITEM, ZE_DESCRI, ZE_QUANT, Z42_VLUNI, ZO_CC, ZO_DESCCC, ZO_PERC, ZS_ITEM 
	ORDER BY ZS_LOCALID, ZE_ITEM 
EndSQL

// Percorre todos os CC para gerar os rateios.
While !SZQQRY->(EOF())
	// Percorre todos os itens para calular e gravar os valores rateados.
	SZEQRY->(DbGoTop())
	While !SZEQRY->(EOF())
		// Grava o item rateado.
		RecLock("SZX", .T.)
		SZX->ZX_FILIAL  := xFilial("SZX")
		SZX->ZX_DOC     := cDoc
		SZX->ZX_ITQQP   := SZEQRY->ZE_ITEM
		SZX->ZX_DESCRI  := SZEQRY->ZE_DESCRI
		SZX->ZX_QTDQQP  := SZEQRY->ZE_QUANT
		SZX->ZX_VLUNI   := SZEQRY->Z42_VLUNI
		SZX->ZX_CC      := SZQQRY->ZQ_CC
		SZX->ZX_DESCC   := SZQQRY->Z5_DESCRI
		SZX->ZX_PERC    := SZEQRY->ZO_PERC
		SZX->ZX_TOTPAT  := SZEQRY->ZQ_TOTPAT
		SZX->ZX_QTRADCC := SZQQRY->ZQ_TOTPAT
		SZX->ZX_QTRATEI := SZQQRY->ZQ_TOTPAT / SZEQRY->ZQ_TOTPAT
		SZX->ZX_VLTOTRA := (SZQQRY->ZQ_TOTPAT / SZEQRY->ZQ_TOTPAT) * SZEQRY->Z42_VLUNI
		MsUnlock()

		SZEQRY->(DbSkip())
	End
	SZQQRY->(DbSkip())
End

SZEQRY->(DbCloseArea())
SZQQRY->(DbCloseArea())

Return
