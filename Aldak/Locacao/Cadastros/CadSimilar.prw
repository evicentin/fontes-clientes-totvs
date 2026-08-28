#include "totvs.ch"
*/------------------------------------------------------------------*/
*/ Rotina: CadSimilar												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 20/10/2025												*/
*/------------------------------------------------------------------*/
*/ Cadastro de Itens Similares.										*/
*/------------------------------------------------------------------*/
User Function CadSimilar()

Local cAlias      := "SZ9"
Private cCadastro := "Cadastro de Itens Similares"
Private aHeader   := {}					 
Private aCols     := {}					 
Private aRotina   := {}					 

AADD(aRotina ,{"Pesquisar" , "AxPesqui"                 , 0, 1})
AADD(aRotina ,{"Visualizar", 'U_ManSim("SZ9",RecNo(),2)', 0, 2})
AADD(aRotina ,{"Incluir"   , 'U_ManSim("SZ9",RecNo(),3)', 0, 3})
AADD(aRotina ,{"Alterar"   , 'U_ManSim("SZ9",RecNo(),4)', 0, 4})
AADD(aRotina ,{"Excluir"   , 'U_ManSim("SZ9",RecNo(),5)', 0, 5})

MBrowse(006, 001, 022, 075, cAlias)

Return

*/------------------------------------------------------------------*/
*/ Rotina: ManSim													*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 20/10/2025												*/
*/------------------------------------------------------------------*/
*/ Cadastro de Itens Similares.										*/
*/------------------------------------------------------------------*/
User Function ManSim(cAlias, nRecNo, nOpc)

Local oDlg     						
Private nOpcA                           

//Seleciona area										
&(cAlias)->(dbSetOrder(1))

//Cria as variaveis de memoria da enchoice
RegToMemory(cAlias, If(nOpc==3, .T., .F.))

//Cria as caixa de diálogo principal
oDlg := TDialog():New(10,10,500,850,"Cadastro de Itens Similares",,,,,,,,,.T.)
oDlg:lCentered := .T.
oDlg:bInit     := EnchoiceBar(oDlg, {|| nOpcA:=1, If(U_SimTudOK(), oDlg:End(),nOpcA := 0)}, {|| oDlg:End()})

//Cria os campos da enchoice.
oEnc := MsMGet():New(cAlias, nRecno, nOpc,,,,,{030,000,070,420},,2,,,, oDlg)

//Carrega as matrizes aHeader e aCols.
MontaHeader(nOpc)

//Monta a estrutura da getdados.
oGet1  := MsGetDados():New(70, 001, 240, 420, nOpc,"U_SimLinOK",,,.T.,,,,,,,,,oDlg)

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
*/ Rotina: MontaHeader												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 20/10/2025												*/
*/------------------------------------------------------------------*/
*/ Monta o aHeader e o aCols.										*/
*/------------------------------------------------------------------*/
Static Function MontaHeader(nOpc)
          
Local nX     := 0
Local nY     := 0
Local nUsado := 0

aHeader := {}
aCols   := {}

//Monta o aHeader.														
nUsado := 0

SX3->(dbSetOrder(1))
SX3->(dbSeek("SZA"))
While !SX3->(EOF()) .and. SX3->X3_ARQUIVO == "SZA"
	If X3USO(SX3->X3_USADO) .and.;
		cNivel >= SX3->X3_NIVEL .and.;
		AllTrim(SX3->X3_CAMPO) <> ("ZA_PRODUTO")
		
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
	For nX := 1 to Len("SZA")
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
	If SZA->(dbSeek(xFilial("SZA") + SZ9->Z9_PRODUTO))
		While SZA->ZA_FILIAL == xFilial("SZA") .and.;
            SZA->ZA_PRODUTO == SZ9->Z9_PRODUTO .and. !SZA->(EOF())
			AADD(aCols, Array(nUsado + 1))
			For nY := 1 to nUsado
				aCols[Len(aCols), nY] := SZA->(FieldGet(FieldPos(aHeader[nY, 2])))
			Next nY
			aCols[Len(aCols), nUsado+1] := .F.
			SZA->(dbSkip())
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
*/ Data  : 20/10/2025												*/
*/------------------------------------------------------------------*/
*/ Atualiza as tabelas.										        */
*/------------------------------------------------------------------*/
Static Function AtuaMod3(nOpc)

Local nX     := 0
Local nY     := 0
Local nZ     := 0
Local bCampo := {|nCPO| Field(nCPO)}

//Inicia alterações no cabecalho.											³
If nOpc == 3
	RecLock("SZ9", .T.)
Else
	RecLock("SZ9", .F.)
EndIf
    
//Se estiver incluindo ou alterando grava o cabecalho (SZ9).				
If nOpc == 3 .or. nOpc == 4
	For nX := 1 to SZ9->(FCount())
		If "FILIAL" $ SZ9->(Field(nX))
			FieldPut(nX, xFilial("SZ9"))
		Else
			FieldPut(nX, M->&(EVAL(bCampo, nX)))
		EndIf
	Next nX
//Se nao estiver incluindo ou alterando exclui o cabecalho (SZ9).			
Else
	SZ9->(dbDelete())
EndIf
MsUnlock()

//Se estiver alterando, apaga os detalhes e cria novamente conforme aCols.
//Se for exlusao, apenas apaga.										    
If nOpc == 4 .or. nOpc == 5
	SZA->(dbSeek(xFilial("SZA") + SZ9->Z9_PRODUTO))
	While SZA->ZA_PRODUTO == SZ9->Z9_PRODUTO .and. !SZA->(EOF())
		RecLock("SZA", .F.)
		SZA->(dbDelete())
		MsUnlock()
		SZA->(dbSkip())
	EndDo
EndIf

//Se estiver incluindo ou alterando, grava os Itens das GetDados.		
If nOpc == 3 .or. nOpc == 4
	For nY := 1 to Len(aCols)
		If aCols[nY][Len(aCols[nY])] == .F.
			RecLock("SZA", .T.)
			SZA->(FieldPut(FieldPos("ZA_FILIAL"), xFilial("SZA")))
			SZA->(FieldPut(FieldPos("ZA_PRODUTO"), M->Z9_PRODUTO))
			For nZ := 1 to Len(aHeader)
				FieldPut(FieldPos(aHeader[nZ, 2]), aCols[nY, nZ])
			Next nZ
			MsUnlock()
		EndIf
	Next nY
EndIf
	
Return

*/------------------------------------------------------------------*/
*/ Rotina: SimLinOK 												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 20/10/2025												*/
*/------------------------------------------------------------------*/
*/ Valida a linha do aCols.										    */
*/------------------------------------------------------------------*/
User Function SimLinOK()

Local cGrupo   := ""
Local cProdSim := aCols[n, GdFieldPos("ZA_PRODSIM", aHeader)]

SB1->(DbSetOrder(1))

If Empty(cProdSim)
    MsgInfo("Digite o produto similar.", "Atenção")
    Return(.F.)
EndIf

If !aCols[n, Len(aCols[n])]
	If SB1->(DbSeek(xFilial("SB1") + M->Z9_PRODUTO))
		cGrupo := SB1->B1_GRUPO
		If SB1->(DbSeek(xFilial("SB1") + cProdsim))
			If SB1->B1_GRUPO <> cGrupo
				MsgInfo("O grupo do produto simular deve ser igual ao do produto principal.", "Atenção")
				Return(.F.)
			EndIf
		EndIf
	EndIf
EndIf

Return(.T.)

*/------------------------------------------------------------------*/
*/ Rotina: SimTudOK 												*/
*/ Autor : Ewerton Vicentin											*/
*/ Data  : 20/10/2025												*/
*/------------------------------------------------------------------*/
*/ Valida os dados da enchoice.										*/
*/------------------------------------------------------------------*/
User Function SimTudOK()

If Empty(M->Z9_PRODUTO)
    MsgInfo("Digite o produto.", "Atenção")
    Return(.F.)
EndIf

If Empty(aCols[1, GdFieldPos("ZA_PRODSIM", aHeader)])
    MsgInfo("Digite o produto similar.", "Atenção")
    Return(.F.)
EndIf

Return(.T.)
