#include "totvs.ch"
*/------------------------------------------------------------------*/
*/ Rotina: CadKit													*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 17/11/2025												*/
*/------------------------------------------------------------------*/
*/ Conferência de notas de remessa.									*/
*/------------------------------------------------------------------*/
User Function ConfNF()

Private cCadastro := "Conferência de Notas de Remessa"
Private aHeader   := {}					 
Private aCols     := {}					 
Private aRotina   := {}					 
Private aCores    := {}

aCores := {{'ZC_STATUS == "P" ', 'BR_VERMELHO'},;
		   {'ZC_STATUS == "C" ', 'BR_VERDE'}}

AADD(aRotina ,{"Pesquisar" , "AxPesqui"                  , 0, 1})
AADD(aRotina ,{"Visualizar", 'U_ManConf("SZC",RecNo(),2)', 0, 2})
AADD(aRotina ,{"Conferir"  , 'U_ManConf("SZC",RecNo(),4)', 0, 4})
AADD(aRotina ,{"Estornar"  , 'U_EstConf()'               , 0, 4})
AADD(aRotina ,{"Importar"  , 'U_ImpConf()'               , 0, 3})
AADD(aRotina ,{"Excluir"   , 'U_ManConf("SZC",RecNo(),5)', 0, 5})
AADD(aRotina ,{"Legenda"   , 'U_ConfLeg()'				 , 0, 5})

MBrowse(006, 001, 022, 075, "SZC",,,,,, aCores)

Return

*/------------------------------------------------------------------*/
*/ Rotina: ManConf													*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 17/11/2025												*/
*/------------------------------------------------------------------*/
*/ Conferência de notas de remessa.									*/
*/------------------------------------------------------------------*/
User Function ManConf(cAlias, nRecNo, nOpc)

Local oDlg
Local cProduto := ""
Local cDoc     := ""
Local cSerie   := ""
Local aButtons := {}
Private aSize  := {}
Private aInfo  := {}
Private aObj   := {}
Private aPObj  := {}
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

If M->ZC_STATUS == "C" .and. nOpc == 4
	MsgInfo("Nota fiscal já conferida.", "Atenção")
EndIf

//Cria as variaveis de memoria da enchoice
RegToMemory(cAlias, .F.)

M->ZC_TIPOMOV := GetMV("LC_LOCTMNF",, "10")

//Cria as caixa de diálogo principal
oDlg := TDialog():New(aSize[7],aSize[1],aSize[6],aSize[5],"Conferência de Notas de Remessa",,,,,,,,,.T.)
oDlg:lCentered := .T.

//Cria os campos da enchoice.
oEnc := MsMGet():New(cAlias, nRecno, nOpc,,,,,aPObj[1],,2,,,, oDlg)

//Carrega as matrizes aHeader e aCols.
MontaHeader(nOpc)

//Monta a estrutura da getdados.
oGet1 := MsGetDados():New(aPObj[2,1]+22,aPObj[2,2],aPObj[2,3],aPObj[2,4], nOpc,"U_ConfLinOK",,,.T.,,,,,,,,,oDlg)
oGet1:oBrowse:bChange := {||;
	cProduto := aCols[N, GdFieldPos("ZD_PRODUTO", aHeader)],;
	cDoc := aCols[N, GdFieldPos("ZD_DOC", aHeader)],;
	cSerie := aCols[N, GdFieldPos("ZD_SERIE", aHeader)]}

//Cria o botão de pesquisa dos patrimônios.
cProduto := aCols[N, GdFieldPos("ZD_PRODUTO", aHeader)]
Aadd(aButtons, {"", {|| U_PesqPat(M->ZC_CODPOST, M->ZC_LOCALID, cProduto, cDoc, cSerie, .T.) },'Patrimônios','Patrimônios'})
oDlg:bInit := EnchoiceBar(oDlg, {|| nOpcA:=1, If(U_ConfTudOK(nOpc), oDlg:End(),nOpcA := 0)}, {|| oDlg:End()},, aButtons)

oDlg:Activate()

//Se incluiu ou alterou algum registro, faz a gravação.
If nOpcA == 1 .and. (nOpc == 4 .or. nOpc == 5)
	BeginTran()
	AtuaMod3(nOpc)
	EndTran()
    ConfirmSX8()
Else
	RollBackSX8()
EndIf

Return

*/------------------------------------------------------------------*/
*/ Rotina: MontaHeader												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 17/11/2025												*/
*/------------------------------------------------------------------*/
*/ Monta o aHeader e o aCols.										*/
*/------------------------------------------------------------------*/
Static Function MontaHeader(nOpc)
          
Local nX     := 0
Local nY     := 0
Local nUsado := 0

SZD->(DbSetOrder(1))

aHeader := {}
aCols   := {}

//Monta o aHeader.														
nUsado := 0

SX3->(dbSetOrder(1))
SX3->(dbSeek("SZD"))
While !SX3->(EOF()) .and. SX3->X3_ARQUIVO == "SZD"
	If X3USO(SX3->X3_USADO) .and.;
		cNivel >= SX3->X3_NIVEL .and.;
		AllTrim(SX3->X3_CAMPO) <> ("ZD_CLIENTE") .and.;
		AllTrim(SX3->X3_CAMPO) <> ("ZD_LOJA")
		
		AADD(aHeader, {Trim(X3TITULO()),;
		SX3->X3_CAMPO   ,;
		SX3->X3_PICTURE ,;
		SX3->X3_TAMANHO ,;
		SX3->X3_DECIMAL ,;
		SX3->X3_VALID   ,;
		SX3->X3_USADO   ,;
		SX3->X3_TIPO    ,;
		SX3->X3_ARQUIVO ,;
		SX3->X3_CONTEXT })
		nUsado++
	Endif
	SX3->(dbSkip())
End

//Monta o aCols.															
//Opcao Inclui.															
If nOpc == 3
	For nX := 1 to Len("SZD")
		nUsado 			   := Len(aHeader)
		aCols  			   := {Array(nUsado+1)}
		aCols[1, nUsado+1] := .F.
		
		For nY := 1 to nUsado
   			aCols[1, nY] := CriaVar(aHeader[nY, 2], .F.)
		Next nY
	Next nX
	
	//Monta o aCols.															
	//Visualiza, Altera e Exclui.												
Else
	nUsado := Len(aHeader)
	If SZD->(dbSeek(xFilial("SZD") + SZC->ZC_DOC + SZC->ZC_SERIE + SZC->ZC_CLIENTE + SZC->ZC_LOJA))
        While SZD->ZD_FILIAL == xFilial("SZD") .and.;
            SZD->ZD_DOC == SZC->ZC_DOC .and.; 
            SZD->ZD_SERIE == SZC->ZC_SERIE .and.; 
            SZD->ZD_CLIENTE == SZC->ZC_CLIENTE .and.; 
            SZD->ZD_SERIE == SZC->ZC_SERIE .and. !SZD->(EOF())
			AADD(aCols, Array(nUsado + 1))
			For nY := 1 to nUsado
				aCols[Len(aCols), nY] := SZD->(FieldGet(FieldPos(aHeader[nY, 2])))
			Next nY
			aCols[Len(aCols), nUsado+1] := .F.
			SZD->(dbSkip())
		End
	//Se nao encontrar nenhum reg., abre um aCols em vazio apenas para exibir.
	Else
		nUsado 			   := Len(aHeader)
		aCols 			   := {Array(nUsado+1)}
		aCols[1, nUsado+1] := .F.
		For nY := 1 to nUsado
			aCols[1, nY] := CriaVar(aHeader[nY, 2], .F.)
		Next nY
	EndIf
EndIf

Return

*/------------------------------------------------------------------*/
*/ Rotina: AtuaMod3 												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 17/11/2025												*/
*/------------------------------------------------------------------*/
*/ Atualiza as tabelas.										        */
*/------------------------------------------------------------------*/
Static Function AtuaMod3(nOpc)

Local nX       := 0
Local cItem    := ""
Local cProduto := ""
Local nQuant   := 0
Local cStatus  := ""
Local bCampo := {|nCPO| Field(nCPO)}

SZD->(DbSetOrder(1))
SZE->(DbSetOrder(1))
SZE->(DbSetOrder(1))
SZJ->(DbSetOrder(2)) // Doc + Série + Cliente + Loja + Item

BeginTran()

//Conferência.
If nOpc == 4
	RecLock("SZC", .F.)
	For nX := 1 to SZC->(FCount())
		If "FILIAL" $ SZC->(Field(nX))
			FieldPut(nX, xFilial("SZC"))
		Else
			FieldPut(nX, M->&(EVAL(bCampo, nX)))
		EndIf
	Next nX
	MsUnlock()

	For nX := 1 to Len(aCols)
		If !aCols[nX, Len(aCols[nX])]
			cDoc     := M->ZC_DOC
			cSerie   := M->ZC_SERIE
			cCliente := M->ZC_CLIENTE
			cLoja    := M->ZC_LOJA
			cItem    := aCols[nX, GdFieldPos("ZD_ITEM", aHeader)]
			cProduto := aCols[nX, GdFieldPos("ZD_PRODUTO", aHeader)]
			nQuant   := aCols[nX, GdFieldPos("ZD_QUANT", aHeader)]
			cStatus  := aCols[nX, GdFieldPos("ZD_STATUS", aHeader)]

			If SZD->(dbSeek(xFilial("SZD") + cDoc + cSerie + cCliente + cLoja + cItem))
				RecLock("SZD", .F.)
				SZD->ZD_QUANT  := nQuant
				SZD->ZD_STATUS := cStatus
				MsUnlock()
			EndIf

			U_GravaEst(M->ZC_CODPOST, M->ZC_LOCALID, cProduto, "01", nQuant, "E")
		EndIf
	Next nX

	RecLock("SZC", .F.)
	SZC->ZC_STATUS := "C"
	MsUnlock()
Else
	//Exclusão
	RecLock("SZC", .F.)
	SZC->(dbDelete())
	MsUnlock()

	For nX := 1 to Len(aCols)
		cItem := aCols[nX, GdFieldPos("ZD_ITEM", aHeader)]
		If SZD->(dbSeek(xFilial("SZD") + M->ZC_DOC + M->ZC_SERIE + M->ZC_CLIENTE + M->ZC_LOJA + cItem))
			RecLock("SZD", .F.)
			SZD->(dbDelete())
			MsUnlock()
		EndIf
	Next nX

	SZJ->(DbSeek(xFilial("SZJ") + M->ZC_DOC + M->ZC_SERIE + M->ZC_CLIENTE + M->ZC_LOJA))
	While SZJ->ZJ_FILIAL == xFilial("SZJ") .and.;
		SZJ->ZJ_DOC == M->ZC_DOC .and.;
		SZJ->ZJ_SERIE == M->ZC_SERIE .and.;
		SZJ->ZJ_CLIENTE == M->ZC_CLIENTE .and.;
		SZJ->ZJ_LOJA == M->ZC_LOJA .and. !SZJ->(EOF())

		RecLock("SZJ", .F.)
		SZJ->(dbDelete())
		MsUnlock()

		SZJ->(DbSkip())
	End
EndIf

EndTran()

Return

*/------------------------------------------------------------------*/
*/ Rotina: ConfLinOK 												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 17/11/2025												*/
*/------------------------------------------------------------------*/
*/ Valida a linha do aCols.										    */
*/------------------------------------------------------------------*/
User Function ConfLinOK()

If Empty(aCols[n, GdFieldPos("ZD_QUANT", aHeader)])
    MsgInfo("A quantidade deve ser maior do que zero.", "Atenção")
    Return(.F.)
EndIf

If aCols[n, GdFieldPos("ZD_QUANT", aHeader)] > aCols[n, GdFieldPos("ZD_QTORI", aHeader)]
    MsgInfo("A quantidade não pode ser maior do que a quantidade original.", "Atenção")
    Return(.F.)
EndIf

Return(.T.)

*/------------------------------------------------------------------*/
*/ Rotina: ConfTudOK 												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 17/11/2025												*/
*/------------------------------------------------------------------*/
*/ Valida os dados da enchoice.										*/
*/------------------------------------------------------------------*/
User Function ConfTudOK(nOpc)

If nOpc == 4
	If Empty(M->ZC_CODPOST)
		MsgInfo("Digite o posto avançado.", "Atenção")
		Return(.F.)
	EndIf

	If Empty(M->ZC_TIPOMOV)
		MsgInfo("Digite o tipo do movimento.", "Atenção")
		Return(.F.)
	EndIf
EndIf

Return(.T.)

*/------------------------------------------------------------------*/
*/ Rotina: ConfLeg   												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 17/11/2025												*/
*/------------------------------------------------------------------*/
*/ Legendas da conferência. 										*/
*/------------------------------------------------------------------*/
User Function ConfLeg()

Local aCores := {}

aCores := {{'BR_VERMELHO', "Pendente"},;
		   {'BR_VERDE'   , "Geradas"}}


BrwLegenda(cCadastro, "Status", aCores)

Return       

*/------------------------------------------------------------------*/
*/ Rotina: ImpConf   												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 17/11/2025												*/
*/------------------------------------------------------------------*/
*/ Importação das notas de remessa.									*/
*/------------------------------------------------------------------*/
User Function ImpConf()

Local oDlg
Local oSay1
Local oButton1, oButton2
Local oMarca
Local oOk     := LoadBitmap( GetResources( ), "LBOK")
Local oNo     := LoadBitmap( GetResources( ), "LBNO")
Local aHeader := {" ","Emissão","Documento","Série","Cliente","Loja","Nome","Total N.F."}
Private oLbx
Private aNF    := {}
Private lMarca := .F.

If !Pergunte("IMPNFREMES", .T.)
	Return
EndIf

If Empty(mv_par11) .or. Empty(mv_par12)
	MsgInfo("É necessário informar o posto avançado e a localidade, verifique os parâmetros.", "Atenção")
	Return
EndIf

SZC->(DbSetOrder(1))

MsgRun("Aguarde, carregando notas fiscais...",, {|| CarregaNF(@aNF)})

If Empty(aNF)
	MsgInfo("Não existem notas de remessa para os parâmetros selecionados.", "Atenção")
	Return
EndIf


DEFINE MSDIALOG oDlg TITLE "Importação Notas de Remessa" FROM 000, 000  TO 600, 900 COLORS 0, 16777215 PIXEL

@ 005, 005 SAY oSay1 PROMPT "Selecione as NF" SIZE 059, 007 OF oDlg COLORS 0, 16777215 PIXEL
@ 285, 360 BUTTON oButton1 PROMPT "Confirmar" ;
	Action(MsgRun("Aguarde, carregando notas fiscais...",, {|| ExecImpNF(aNF), oDlg:End()})) SIZE 037, 012 OF oDlg PIXEL

@ 285, 005 CHECKBOX oMarca VAR lMarca PROMPT "Marca / Desmarca Todos" SIZE 079, 008 OF oDlg COLORS 0, 16777215 PIXEL
oMarca:bChange := {|| InvertMark()}


@ 285, 400 BUTTON oButton2 PROMPT "Cancelar" Action(oDlg:End()) SIZE 037, 012 OF oDlg PIXEL

oLbx := TWBrowse():New(015, 005, 445, 266,, aHeader,, oDlg,,,,,,,,,,,, .F.,, .T.,, .F.)

oLbx:SetArray(aNF)
oLbx:bLine := {|| {If(aNF[oLbx:nAT, 1], oOk, oNo),;	
                      aNF[oLbx:nAT, 2],;
					  aNF[oLbx:nAT, 3],;
					  aNF[oLbx:nAT, 4],;
					  aNF[oLbx:nAT, 5],;
					  aNF[oLbx:nAT, 6],;
					  aNF[oLbx:nAT, 7],;
					  aNF[oLbx:nAT, 8]}}

oLbx:bLDblClick := {|| aNF[oLbx:nAt,1] := !aNF[oLbx:nAt,1]}

ACTIVATE MSDIALOG oDlg CENTERED

Return

*/------------------------------------------------------------------*/
*/ Rotina: CarregaNF   												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 17/11/2025												*/
*/------------------------------------------------------------------*/
*/ Executa a importação das notas de remessa.						*/
*/------------------------------------------------------------------*/
Static Function CarregaNF(aNF)

SZC->(DbSetOrder(1))

BeginSQL Alias "SF2QRY"
	SELECT 
		F2_CLIENTE, F2_LOJA, F2_DOC, F2_SERIE, F2_EMISSAO, F2_VALBRUT, A1_NREDUZ
	FROM 
		%tABLE:SF2% SF2
		INNER JOIN %Table:SA1% SA1 ON A1_COD = f2_CLIENTE AND A1_LOJA = F2_LOJA
	WHERE
		F2_FILIAL = %xFilial:SF2% AND
		F2_EMISSAO BETWEEN %Exp:DtoS(mv_par01)% AND %Exp:DtoS(mv_par02)% AND
		F2_CLIENTE BETWEEN %Exp:mv_par03% AND %Exp:mv_par05% AND
		F2_LOJA BETWEEN %Exp:mv_par04% AND %Exp:mv_par06% AND
		F2_DOC BETWEEN %Exp:mv_par07% AND %Exp:mv_par08% AND
		F2_SERIE BETWEEN %Exp:mv_par09% AND %Exp:mv_par10% AND
		SA1.%NotDel% AND
		SF2.%NotDel%
EndSQL

TCSetField("SF2QRY", "F2_EMISSAO", "D", 8, 0)
TCSetField("SF2QRY", "F2_VALBRUT", "N",TamSX3("F2_VALBRUT")[1], TamSX3("F2_VALBRUT")[2])

While !SF2QRY->(EOF())
	If !SZC->(DbSeek(xFilial("SZC") + SF2QRY->F2_DOC + SF2QRY->F2_SERIE + SF2QRY->F2_CLIENTE + SF2QRY->F2_LOJA))
		Aadd(aNF, {.F.,;
			SF2QRY->F2_EMISSAO,;
			SF2QRY->F2_DOC,;
			SF2QRY->F2_SERIE,;
			SF2QRY->F2_CLIENTE,;
			SF2QRY->F2_LOJA,;
			AllTrim(SF2QRY->A1_NREDUZ),;
			SF2QRY->F2_VALBRUT})
	EndIf
	SF2QRY->(DbSkip())
End
SF2QRY->(DbCloseArea())

Return

*/------------------------------------------------------------------*/
*/ Rotina: ExecImpNF   												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 17/11/2025												*/
*/------------------------------------------------------------------*/
*/ Executa a importação das notas de remessa.						*/
*/------------------------------------------------------------------*/
Static Function ExecImpNF(aNF)

Local nX      := 0
Local cPatrim := ""

SB1->(DbSetOrder(1)) // Código
SD2->(DbSetOrder(3)) // Doc + Série + Cliente + Loja
ST9->(DbSetOrder(7)) // Cod.Produto
Z01->(DbSetOrder(3)) // Pedido + Item + Produto

For nX := 1 to Len(aNF)
	If aNF[nX, 1]
		BeginTran()
		RecLock("SZC", .T.)
		SZC->ZC_FILIAL  := xFilial("SZC")
		SZC->ZC_CODPOST := mv_par11
		SZC->ZC_LOCALID := mv_par12
		SZC->ZC_EMISSAO := aNF[nX, 2]
		SZC->ZC_DOC     := aNF[nX, 3]
		SZC->ZC_SERIE   := aNF[nX, 4]
		SZC->ZC_CLIENTE := aNF[nX, 5]
		SZC->ZC_LOJA    := aNF[nX, 6]
		SZC->ZC_NOME    := aNF[nX, 7]
		SZC->ZC_VALBRUT := aNF[nX, 8]
		SZC->ZC_STATUS  := "P"
		MsUnlock()

		If SD2->(DbSeek(xFilial("SD2") + aNF[nX, 3] + aNF[nX, 4] + aNF[nX, 5] + aNF[nX, 6]))
			While SD2->D2_FILIAL == xFilial("SD2") .and.;
				SD2->D2_DOC == aNF[nX, 3] .and.;
				SD2->D2_SERIE == aNF[nX, 4] .and.;
				SD2->D2_CLIENTE == aNF[nX, 5] .and.;
				SD2->D2_LOJA == aNF[nX, 6]  .and. !SD2->(EOF())

				SB1->(DbSeek(xFilial("SB1") + SD2->D2_COD))

				// Se existir na ST9 é porque controla patrimônio.
				If ST9->(DbSeek(xFilial("ST9") + SD2->D2_COD))
					cPatrim := "S"

					Z01->(DbSeek(xFilial("Z01") + SD2->D2_PEDIDO + SD2->D2_ITEMPV + SD2->D2_COD))
					While Z01->Z01_FILIAL == xFilial("Z01") .and.;
						Z01->Z01_PEDIDO == SD2->D2_PEDIDO .and.;
						Z01->Z01_ITEMPD == SD2->D2_ITEMPV .and.; 
						Z01->Z01_PRODUT == SD2->D2_COD .and. !Z01->(EOF())
						RecLock("SZJ", .T.)
						SZJ->ZJ_FILIAL  := xFilial("SZJ")
						SZJ->ZJ_CODPOST := mv_par11
						SZJ->ZJ_LOCALID := mv_par12
						SZJ->ZJ_DOC     := aNF[nX, 3]
						SZJ->ZJ_SERIE   := aNF[nX, 4]
						SZJ->ZJ_CLIENTE := aNF[nX, 5]
						SZJ->ZJ_LOJA    := aNF[nX, 6]
						SZJ->ZJ_ITEM    := SD2->D2_ITEM
						SZJ->ZJ_PRODUTO := SD2->D2_COD
						SZJ->ZJ_PATRIM  := Z01->Z01_CHATF
						SZJ->ZJ_NUMSER  := Z01->Z01_CHASSI
						SZJ->ZJ_ESN		:= Z01->Z01_ESN
						SZJ->ZJ_LOCADO	:= "N"
						MsUnlock()
						Z01->(DbSkip())
					End
				Else
					cPatrim := "N"
				EndIf

				RecLock("SZD", .T.)
				SZD->ZD_FILIAL  := xFilial("SZD")
				SZD->ZD_DOC     := aNF[nX, 3]
				SZD->ZD_SERIE   := aNF[nX, 4]
				SZD->ZD_CLIENTE := aNF[nX, 5]
				SZD->ZD_LOJA    := aNF[nX, 6]
				SZD->ZD_ITEM    := SD2->D2_ITEM
				SZD->ZD_PRODUTO := SD2->D2_COD
				SZD->ZD_DESCRI  := SB1->B1_DESC
				SZD->ZD_UM      := SD2->D2_UM
				SZD->ZD_QTORI   := SD2->D2_QUANT
				SZD->ZD_QUANT   := SD2->D2_QUANT
				SZD->ZD_PRCVEN  := SD2->D2_PRCVEN
				SZD->ZD_TOTAL   := SD2->D2_TOTAL
				SZD->ZD_PATRIM  := cPatrim
				SZD->ZD_TES     := SD2->D2_TES
				SZD->ZD_STATUS  := "C"
				MsUnlock()

				SD2->(DbSkip())
			End
		EndIf
		EndTran()
	EndIf
Next nX

SZC->(DbGoTop())

Return

*/------------------------------------------------------------------*/
*/ Rotina: InvertMark												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 25/11/2025												*/
*/------------------------------------------------------------------*/
*/ Marca/desmarca todas as notas fiscais.							*/
*/------------------------------------------------------------------*/
Static Function InvertMark()

Local nX

For nX := 1 to Len(aNF)
	aNF[nX, 1] := lMarca
Next nX

oLbx:Refresh()

Return                                                   
