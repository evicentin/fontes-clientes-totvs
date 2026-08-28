#include "totvs.ch"
*/------------------------------------------------------------------*/
*/ Rotina: Fecham													*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 25/11/2025												*/
*/------------------------------------------------------------------*/
*/ Fechamento dos valores das locações.								*/
*/------------------------------------------------------------------*/
User Function Fecham()

Local cAlias      := "SZP"
Local cFiltro     := U_MBLocxUsr(1, cAlias)
Local aCores      := {}
Private cCadastro := "Fechamento dos Valores de Locação"
Private aHeader   := {}
Private aCols     := {}
Private aRotina   := {}
Private aIndex    := {}
Private bFiltraBrw:= {|| FilBrowse(cAlias, @aIndex, @cFiltro)}

AADD(aRotina ,{"Pesquisar" 			, "AxPesqui"                 			, 0, 1})
AADD(aRotina ,{"Visualizar"			, 'U_ManFecha("SZP",SZP->(RecNo()),2)'	, 0, 2})
AADD(aRotina ,{"Gerar Fechamento"	, 'U_GeraFecha()'						, 0, 3})
AADD(aRotina ,{"Alterar"			, 'U_ManFecha("SZP",SZP->(RecNo()),4)'	, 0, 4})
AADD(aRotina ,{"Estornar"  			, 'U_ManFecha("SZP",SZP->(RecNo()),5)'	, 0, 5})

Eval(bFiltraBrw)

MBrowse(006, 001, 022, 075, cAlias,,,,,,aCores)

EndFilBrw(cAlias, aIndex)

Return

*/------------------------------------------------------------------*/
*/ Rotina: ManFecha													*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 25/11/2025												*/
*/------------------------------------------------------------------*/
*/ Manutenção das locações. 										*/
*/------------------------------------------------------------------*/
User Function ManFecha(cAlias, nRecNo, nOpc)

Local oDlg
Local aHeader1     := {}
Local aHeader2     := {}
Local aCols1       := {}
Local aCols2       := {}
Local aFieldsKit   := {"ZQ_STATUS","ZQ_ITEM","ZQ_LOCALID","ZQ_DESCLOC","ZQ_CC","ZQ_KIT","DESCKIT","ZQ_VALOR","ZQ_QUANT","ZQ_PRODUTO",;
					   "ZQ_DESCPRO","ZQ_DOCENT","ZQ_CODRESP","ZQ_NOME","ZQ_PATRIM","ZQ_ISSI"}
Local aAltFldKit   := {}
Local aFieldsLan   := {"ZR_PRODUTO","ZR_DESCRI","ZR_QUANT","ZR_VALOR"}
Local aFieldsAlt   := {"ZR_PRODUTO","ZR_QUANT","ZR_VALOR"}
Private oGet1
Private oGet2
Private aSize      := {}
Private aInfo      := {}
Private aObj       := {}
Private aPObj      := {}
Private nOpcA                           

// Retorna a área útil das janelas Protheus
aSize := MsAdvSize()

// Será utilizado três áreas na janela
// 1ª - Enchoice, sendo 135 pontos pixel
// 2ª - MsGetDados, o que sobrar em pontos pixel é para este objeto
AADD( aObj, { 100, 135, .T., .F. })
AADD( aObj, { 100, 100, .T., .T. })

// Cálculo automático da dimensões dos objetos (altura/largura) em pixel
aInfo := { aSize[1], aSize[2], aSize[3], aSize[4], 3, 3 }
aPObj := MsObjSize( aInfo, aObj )

//Seleciona area										
&(cAlias)->(dbSetOrder(1))

//Cria as variaveis de memoria da enchoice
RegToMemory(cAlias, If(nOpc==3, .T., .F.))

//Cria as caixa de diálogo principal
oDlg := TDialog():New(aSize[7],aSize[1],aSize[6],aSize[5],"Fechamento de Valores de Locação",,,,,,,,,.T.)
oDlg:lCentered := .T.

//Cria os campos da enchoice.
oEnc := MsMGet():New(cAlias, nRecno, 2,,,,,aPObj[1],,2,,,, oDlg)

//Carrega as matrizes aHeader e aCols.
HeaderSZQ(@aHeader1, @aCols1, aFieldsKit)
HeaderSZR(@aHeader2, @aCols2, aFieldsLan)

//Monta a estrutura das getdados.
@ aPObj[2,1],aPObj[2,2] FOLDER oFolder SIZE aPObj[2,4],aPObj[2,3] OF oDlg ITEMS "Kits/Rateios","Lançamentos Extras";
	COLORS 0, 14215660 PIXEL

// Kits / Rateios
oGet1 := MsNewGetDados():New(005,005,aPObj[2,3]-185,aPObj[2,4]-5, GD_INSERT+GD_DELETE+GD_UPDATE, "U_FecLinOK", "AllwaysTrue",;
	 "+ZI_ITEM", aAltFldKit,, 999, "AllwaysTrue", "", "AllwaysTrue", oFolder:aDialogs[1], aHeader1, aCols1)

// Lançamentos Extras.
oGet2 := MsNewGetDados():New(005,005,aPObj[2,3]-185,aPObj[2,4]-5, GD_INSERT+GD_DELETE+GD_UPDATE, "U_LanLinOK", "AllwaysTrue",;
	 "+Field1+Field2", if(nOpc==4, aFieldsAlt, {}),, 999, "AllwaysTrue", "", "AllwaysTrue", oFolder:aDialogs[2], aHeader2, aCols2)

oDlg:bInit := EnchoiceBar(oDlg, {|| nOpcA:=1, If(U_FechaTOK(), oDlg:End(),nOpcA:=0)}, {|| oDlg:End()})

oDlg:Activate() 

//Se incluiu ou alterou algum registro, faz a gravação.
If nOpcA == 1 .and. (nOpc == 3 .or. nOpc == 4 .or. nOpc == 5)
	BeginTran()
	AtuaMod3(nOpc)
	EndTran()
    ConfirmSX8()
Else
	RollBackSX8()
EndIf

Return

*/------------------------------------------------------------------*/
*/ Rotina: HeaderSZQ												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 20/10/2025												*/
*/------------------------------------------------------------------*/
*/ Monta o aHeader e o aCols.										*/
*/------------------------------------------------------------------*/
Static Function HeaderSZQ(aHeader1, aCols1, aFieldsKit)

Local nX   := 0
Local nTam := 0
Local aFieldFill   := {}

SX3->(DbSetOrder(2))
SZR->(dbSetOrder(1))

//Monta o aHeader.
For nX := 1 to Len(aFieldsKit)
	If SX3->(DbSeek(aFieldsKit[nX]))
		Aadd(aHeader1, {AllTrim(X3Titulo()),SX3->X3_CAMPO,SX3->X3_PICTURE,SX3->X3_TAMANHO,SX3->X3_DECIMAL,SX3->X3_VALID,;
		                  SX3->X3_USADO,SX3->X3_TIPO,SX3->X3_F3,SX3->X3_CONTEXT,SX3->X3_CBOX,SX3->X3_RELACAO})
	Endif
Next nX
   
//Monta o aCols.
If SZQ->(DbSeek(xFilial("SZQ") + SZP->ZP_DOC))
    While SZQ->ZQ_FILIAL == xFilial("SZQ") .and.;
        SZQ->ZQ_DOC == SZP->ZP_DOC .and.;
        !SZQ->(EOF())
        aFieldFill := {}
        For nX := 1 to Len(aFieldsKit)
            If SX3->(DbSeek(aFieldsKit[nX]))
                Aadd(aFieldFill, SZQ->(FieldGet(FieldPos(aFieldsKit[nX]))))
            Endif
        Next nX
        Aadd(aFieldFill, .F.)
        Aadd(aCols1, aFieldFill)
        SZQ->(dbSkip())
    End
Else
    nTam := Len(aHeader1)
    aCols1 := {Array(nTam + 1)}
    For nX := 1 to nTam
        aCols1[1, nX]  := CriaVar(aHeader1[nX, 2], .F.)
    Next nX
	aCols1[1, nTam + 1] := .F.
EndIf

Return

*/------------------------------------------------------------------*/
*/ Rotina: HeaderSZR												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 20/10/2025												*/
*/------------------------------------------------------------------*/
*/ Monta o aHeader e o aCols.										*/
*/------------------------------------------------------------------*/
Static Function HeaderSZR(aHeader2, aCols2, aFieldsLan)

Local nX   := 0
Local nTam := 0
Local aFieldFill   := {}

SX3->(DbSetOrder(2))
SZR->(dbSetOrder(1))

//Monta o aHeader.
For nX := 1 to Len(aFieldsLan)
	If SX3->(DbSeek(aFieldsLan[nX]))
		Aadd(aHeader2, {AllTrim(X3Titulo()),SX3->X3_CAMPO,SX3->X3_PICTURE,SX3->X3_TAMANHO,SX3->X3_DECIMAL,SX3->X3_VALID,;
		                  SX3->X3_USADO,SX3->X3_TIPO,SX3->X3_F3,SX3->X3_CONTEXT,SX3->X3_CBOX,SX3->X3_RELACAO})
	Endif
Next nX
   
//Monta o aCols.
If SZR->(DbSeek(xFilial("SZR") + SZP->ZP_DOC))
    While SZR->ZR_FILIAL == xFilial("SZR") .and.;
        SZR->ZR_DOC == SZP->ZP_DOC .and.;
        !SZR->(EOF())
        aFieldFill := {}
        For nX := 1 to Len(aFieldsLan)
            If SX3->(DbSeek(aFieldsLan[nX]))
                Aadd(aFieldFill, SZR->(FieldGet(FieldPos(aFieldsLan[nX]))))
            Endif
        Next nX
        Aadd(aFieldFill, .F.)
        Aadd(aCols2, aFieldFill)
        SZR->(dbSkip())
    End
Else
    nTam := Len(aHeader2)
    aCols2 := {Array(nTam + 1)}
    For nX := 1 to nTam
        aCols2[1, nX]  := CriaVar(aHeader2[nX, 2], .F.)
    Next nX
	aCols2[1, nTam + 1] := .F.
EndIf

Return

*/------------------------------------------------------------------*/
*/ Rotina: AtuaMod3 												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 25/11/2025												*/
*/------------------------------------------------------------------*/
*/ Atualiza as tabelas.										        */
*/------------------------------------------------------------------*/
Static Function AtuaMod3(nOpc)

Local nY     := 0
Local nZ     := 0

//Inicia alterações no cabecalho.
If nOpc == 5
	RecLock("SZP", .F.)
	SZP->(dbDelete())
	MsUnlock()
EndIf
    
//Se estiver alterando, apaga os detalhes e cria novamente conforme aCols.
//Se for exlusao, apenas apaga.										    
If nOpc == 4 .or. nOpc == 5
	If nOpc == 5
		SZQ->(dbSeek(xFilial("SZQ") + SZP->ZP_DOC))
		While SZQ->ZQ_FILIAL == xFilial("SZQ") .and.;
			SZQ->ZQ_DOC == SZP->ZP_DOC .and. !SZQ->(EOF())
			RecLock("SZQ", .F.)
			SZQ->(dbDelete())
			MsUnlock()
			SZQ->(dbSkip())
		EndDo
	EndIf

	SZR->(dbSeek(xFilial("SZR") + SZP->ZP_DOC))
	While SZR->ZR_FILIAL == xFilial("SZR") .and.;
        SZR->ZR_DOC == SZP->ZP_DOC .and. !SZR->(EOF())
		RecLock("SZR", .F.)
		SZR->(dbDelete())
		MsUnlock()
		SZR->(dbSkip())
	EndDo
EndIf

//Se estiver incluindo ou alterando, grava os Itens das GetDados.		
If nOpc == 3 .or. nOpc == 4
	For nY := 1 to Len(oGet2:aCols)
		If oGet2:aCols[nY, Len(oGet2:aCols[nY])] == .F.
			RecLock("SZR", .T.)
			SZR->(FieldPut(FieldPos("ZR_FILIAL"), xFilial("SZR")))
			SZR->(FieldPut(FieldPos("ZR_DOC"), M->ZP_DOC))
			For nZ := 1 to Len(oGet2:aHeader)
				FieldPut(FieldPos(oGet2:aHeader[nZ, 2]), oGet2:aCols[nY, nZ])
			Next nZ
			MsUnlock()
		EndIf
	Next nY
EndIf
	
Return

*/------------------------------------------------------------------*/
*/ Rotina: FecLinOK 												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 25/11/2025												*/
*/------------------------------------------------------------------*/
*/ Valida a linha do aCols.										    */
*/------------------------------------------------------------------*/
User Function FecLinOK()

Return(.T.)

*/------------------------------------------------------------------*/
*/ Rotina: LanLinOK 												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 25/11/2025												*/
*/------------------------------------------------------------------*/
*/ Valida a linha do aCols.										    */
*/------------------------------------------------------------------*/
User Function LanLinOK()

Return(.T.)

*/------------------------------------------------------------------*/
*/ Rotina: FechaTOK 												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 25/11/2025												*/
*/------------------------------------------------------------------*/
*/ Valida os dados da enchoice.										*/
*/------------------------------------------------------------------*/
User Function FechaTOK()

Return(.T.)

*/------------------------------------------------------------------*/
*/ Rotina: ValidPer													*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 25/11/2025												*/
*/------------------------------------------------------------------*/
*/ Valida o período do fechamento.									*/
*/------------------------------------------------------------------*/
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

*/------------------------------------------------------------------*/
*/ Rotina: GeraFecha												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 25/11/2025												*/
*/------------------------------------------------------------------*/
*/ Executa o fechamento.											*/
*/------------------------------------------------------------------*/
User Function GeraFecha()

Local cMesFecha := ""
Local cAnoFecha := ""
Local dDataIni  := Ctod("")
Local dDataFim  := Ctod("")
Local dDiaCorte := CtoD("")

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

	dDataIni  := CtoD(StrZero(Val(SZ1->Z1_DIAFECH), 2) + "/" + cMesIni + "/" + cAnoIni)
	dDataFim  := CtoD(StrZero(Val(SZ1->Z1_DIAFECH), 2) + "/" + cMesFim + "/" + cAnoFim)
	dDiaCorte := CtoD(StrZero(Val(SZ1->Z1_DIACORT), 2) + "/" + cMesFim + "/" + cAnoFim)
Else
	MsgInfo("Posto avançado não encontrado.", "Atenção")
	Return
EndIf

If SZP->(DbSeek(xFilial("SZP") + mv_par01 + mv_par02))
	MsgInfo("Já existe fechamento nesse período.", "Atenção")
	Return
EndIf

MsgRun("Aguarde, carregando movimentos...",, {|| ProcFecha(dDataIni, dDataFim, dDiaCorte)})

Return

*/------------------------------------------------------------------*/
*/ Rotina: ProcFecha												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 25/11/2025												*/
*/------------------------------------------------------------------*/
*/ Executa o fechamento.											*/
*/------------------------------------------------------------------*/
Static Function ProcFecha(dDataIni, dDataFim, dDiaCorte)

Local nValor   := 0
Local cDoc     := ""
Local cCodResp := ""
Local cNome    := ""
Local cDescKit := ""
Local cItem    := "000"

BeginSQL Alias "SZIQRY"
	SELECT
		ZI_CODPOST, ZI_LOCALID, ZI_DOC, ZI_PRODUTO, ZI_DESCRI, ZI_PATRIM, ZI_ISSI, ZI_CODKIT, ZI_QUANT, ZI_LOCALIZ, ZI_DATAMOV, 
		ZI_DATADEV, ZI_DESCRI, ZH_CC, ZH_STATUS
	FROM
		%Table:SZI% SZI
		INNER JOIN %Table:SZH% SZH ON ZH_DOC = ZI_DOC
		INNER JOIN %Table:SZ1% SZ1 ON Z1_CODPOST = ZH_CODPOST
	WHERE
		ZI_FILIAL = %xFilial:SZI% AND
		ZH_FILIAL = %xFilial:SZH% AND
		Z1_FILIAL = %xFilial:SZ1% AND
		ZH_CODPOST = %Exp:mv_par01% AND
		ZI_STATUS IN ('A', 'D') AND
		ZI_PATRIM <> '' AND
		(ZI_DATADEV >= %Exp:DtoS(dDataIni)% AND ZI_DATADEV <= %Exp:DtoS(dDataFim)% OR ZI_DATADEV = '') AND
		SZI.%NotDel% AND
		SZH.%NotDel% AND
		SZ1.%NotDel%
		ORDER BY ZH_LOCALID, ZH_CC, ZI_PRODUTO, ZI_PATRIM
EndSQL

If !SZIQRY->(EOF())
	SZ2->(DbSeek(xFilial("SZ2") + SZIQRY->ZI_LOCALID))

	BeginTran()

	cDoc := GetSXENum("SZP", "ZP_DOC")

	RecLock("SZP", .T.)
	SZP->ZP_FILIAL  := xFilial("SZP")
	SZP->ZP_DOC     := cDoc
	SZP->ZP_CODPOST := SZIQRY->ZI_CODPOST
	SZP->ZP_PERIODO := SubStr(mv_par02, 1, 2) + "/" + SubStr(mv_par02, 3, 4)
	SZP->ZP_DTFECHA := dDataBase
	MsUnlock()

	While !SZIQRY->(EOF())
		cItem    := Soma1(cItem)
		cCodResp := ""
		cNome    := ""
		cDescKit := ""

		// Busca dados do responsável.
		If SZH->(DbSeek(xFilial("SZH") + SZIQRY->ZI_DOC))
			If SZ0->(DbSeek(xFilial("SZ0") + SZI->ZI_CODPOST + SZH->ZH_CODRESP))
				cCodResp := SZ0->Z0_CODRESP
				cNome    := SZ0->Z0_NOME
			EndIf
		EndIf
		
		// Busca dados do kit.
		If Z20->(DbSeek(xFilial("Z20") + SZIQRY->ZI_CODKIT))
			cDescKit := Z20->Z20_DESCR
		EndIf

		// Busca o valor a ser apropriado.
		nValor := 0
		// Verifica documentos de entrega, nesse caso como é o documento inicial da locação, já busca o valor
		// direto nas tabelas de primeira locação e tabela de preço do contrato.
		If SZIQRY->ZH_STATUS == "A" // Ativo (Entrega).
			cPatOri := SZIQRY->ZI_PATRIM
		// Se for uma substituição, precisa buscar o item original que foi entregue na prmeira entrega,
		// porque o valor deve ser do item inicial da locação e não o atual que é o substituto.
		ElseIf SZIQRY->ZH_STATUS == "S" // Substituição
			cPatOri := U_PatrimOri(SZIQRY->ZI_DOC)
		EndIf

		// Com o patrimônio correto, busca o valor da primeira locação dele naquele posto avançado / localidade.
		If SZK->(DbSeek(xFilial("SZK") + SZIQRY->ZI_CODPOST + SZIQRY->ZI_LOCALID + SZIQRY->ZI_CODKIT + cPatOri)) 
			nValor := SZK->ZK_VALOR
			// Como prevenção, se o valor vier zerado, vamos buscar da tabela de valores de contrato atualzada.
			// Porém, isso não deveria ocorrer, visto que a tabela SZK SEMPRE é atualizada  quando ocorre um 
			// movimento do patrimônio.
			If nValor == 0
				If SZL->(DbSeek(xFilial("SZL") + SZIQRY->ZI_CODPOST + SZIQRY->ZI_LOCALID + SZIQRY->ZI_CODKIT))
					While SZL->ZL_FILIAL == xFilial("SZL") .and.;
						SZL->ZL_CODPOST == SZIQRY->ZI_CODPOST .and.;
						SZL->ZL_LOCALID == SZIQRY->ZI_LOCALID .and.;
						SZL->ZL_CODKIT == SZIQRY->ZI_CODKIT .and. !SZL->(EOF())
						
						If SZL->ZL_DATADE <= dDataBase .and. SZL->ZL_DATAATE >= dDataBase
							nValor := SZL->ZL_VALOR
							Exit
						EndIf
						
						SZL->(DbSkip())
					End
				EndIf
			EndIf
			// Se a data de entrega for maior do que a data de corte, não cobra locação.
			// Regra para atender data de entrega ocorrendo na segunda quinzena, nesse caso anda não cobra.
			If StoD(SZIQRY->ZI_DATAMOV) >= dDiaCorte .and. SZIQRY->ZH_STATUS == "A" // Entrega
				nValor := 0
			EndIf
		EndIf

		RecLock("SZQ", .T.)
		SZQ->ZQ_FILIAL  := xFilial("SZQ")
		SZQ->ZQ_DOC     := cDoc
		SZQ->ZQ_STATUS  := "N"
		SZQ->ZQ_ITEM    := cItem
		SZQ->ZQ_LOCALID := SZIQRY->ZI_LOCALID
		SZQ->ZQ_DESCLOC := SZ2->Z2_DESCRI
		SZQ->ZQ_CC 		:= SZIQRY->ZH_CC
		SZQ->ZQ_KIT     := SZIQRY->ZI_CODKIT
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

	EndTran()
Else
	MsgInfo("Sem movimentos para os parâmetros informados.", "Atenção")
	Return
EndIf

Return

*/------------------------------------------------------------------*/
*/ Rotina: ValidGet2												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 25/11/2025												*/
*/------------------------------------------------------------------*/
*/ Validação do campo de produto dos lançamentos extras.			*/
*/------------------------------------------------------------------*/
User Function ValidGet2()

Local nPosDesc := GdFieldPos("ZR_DESCRI", oGet2:aHeader)
Local cProduto := Alltrim(&(ReadVar())) 

BeginSQL Alias "SB1QRY"
	SELECT
		B1_DESC
	FROM
		%Table:SB1%
	WHERE
		B1_FILIAL = %xFilial:SB1% AND
		B1_COD = %Exp:cProduto% AND
		%NotDel%
EndSQL

If !SB1QRY->(EOF())
	oGet2:aCols[oGet2:nAt, nPosDesc] := SB1QRY->B1_DESC
Else
	MsgInfo("Produto não encontrado.", "Atenção")
	SB1QRY->(DbCloseArea())
	Return(.F.)
EndIf
SB1QRY->(DbCloseArea())

Return(.T.)
