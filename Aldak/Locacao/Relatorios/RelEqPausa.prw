#include "protheus.ch"

User Function RelPausa()
      
Local aMovimento := {}

If !Pergunte("RELMOVPATR", .T.)
	Return
EndIf

MsgRun("Aguarde, carregando equipamentos pausados...",, {|| ProcRel(@aMovimento)})
MsgRun("Aguarde, carregando planilha Excel...",, {|| GeraExcel(aMovimento)})

Return            

Static Function ProcRel(aMovimento)
                   
//aMovimento[1] - Status
//aMovimento[2] - Produto
//aMovimento[3] - Descrição
//aMovimento[4] - Localidade
//aMovimento[5] - Patrimônio
//aMovimento[6] - Núm.Série
//aMovimento[7] - Dt.Entrega
//aMovimento[8] - Responsável
//aMovimento[9] - Diretoria
//aMovimento[10] - Gerência Geral
//aMovimento[11] - Gerência de Área
//aMovimento[12] - Coordenação
//aMovimento[13] - Supervisão

BeginSQL Alias "SZIQRY"
SELECT
	ZI_STATUS, ZI_PRODUTO, ZI_PATRIM, ZI_NUMSER, ZI_DESCRI, ZI_DATAMOV, ZH_LOCALID, ZH_CODRESP, ZH_CC, Z2_DESCRI, Z0_NOME
FROM
	%Table:SZI% SZI
	INNER JOIN %Table:SZH% SZH ON ZH_DOC = ZI_DOC
	INNER JOIN %Table:SZ2% SZ2 ON Z2_LOCALID = ZH_LOCALID
	INNER JOIN %Table:SZ0% SZ0 ON ZH_CODRESP = Z0_CODRESP
WHERE
	ZI_FILIAL = %xFilial:SZI% AND
	ZH_FILIAL = %xFilial:SZH% AND
	Z2_FILIAL = %xFilial:SZ2% AND
	Z0_FILIAL = %xFilial:SZ0% AND
	ZH_CODPOST BETWEEN %Exp:mv_par01% AND %Exp:mv_par02% AND
	ZH_LOCALID BETWEEN %Exp:mv_par03% AND %Exp:mv_par04% AND
	ZI_PATRIM BETWEEN %Exp:mv_par05% AND %Exp:mv_par06% AND
	ZI_DATAMOV BETWEEN %Exp:DtoS(mv_par07)% AND %Exp:DtoS(mv_par08)% AND
	ZI_STATUS = 'P' AND
	SZI.%NotDel% AND
	SZH.%NotDel% AND
	SZ2.%NotDel% AND
	SZ0.%NotDel%
	ORDER BY ZI_DOC, ZI_ITEM
EndSQL
    
aNiveisCC := U_RetNivelCC(SZIQRY->ZH_CC)

While !SZIQRY->(EOF())
	aAdd(aMovimento, {;
		SZIQRY->ZI_STATUS,;
		SZIQRY->ZI_PRODUTO,;
		SZIQRY->ZI_DESCRI,;
		SZIQRY->Z2_DESCRI,;
		SZIQRY->ZI_PATRIM,;
		SZIQRY->ZI_NUMSER,;
		StoD(SZIQRY->ZI_DATAMOV),;
		SZIQRY->Z0_NOME,;
		aNiveisCC[1, 2],;
		aNiveisCC[2, 2],;
		aNiveisCC[3, 2],;
		aNiveisCC[4, 2],;
		aNiveisCC[5, 2],;
		})
	SZIQRY->(DbSkip())
End
SZIQRY->(DbCloseArea())

Return

Static Function GeraExcel(aMovimento)

Local nX		    := 0
Local oExcel    := FWMSEXCEL():New()
Local cDirDocs  := MsDocPath()
Local cPath		:= AllTrim(GetTempPath())

oExcel:AddworkSheet("Equipamentos")
oExcel:AddTable ("Equipamentos","Locação Pausada")

//aMovimento[1] - Status
//aMovimento[2] - Produto
//aMovimento[3] - Descrição
//aMovimento[4] - Localidade
//aMovimento[5] - Patrimônio
//aMovimento[6] - Núm.Série
//aMovimento[7] - Dt.Entrega
//aMovimento[8] - Responsável
//aMovimento[9] - Diretoria
//aMovimento[10] - Gerência Geral
//aMovimento[11] - Gerência de Área
//aMovimento[12] - Coordenação
//aMovimento[13] - Supervisão

oExcel:AddColumn("Equipamentos","Locação Pausada","Movimento",1,1,.F.)
oExcel:AddColumn("Equipamentos","Locação Pausada","Produto",1,1,.F.)
oExcel:AddColumn("Equipamentos","Locação Pausada","Descrição",1,1,.F.)
oExcel:AddColumn("Equipamentos","Locação Pausada","Localidade",1,1,.F.)
oExcel:AddColumn("Equipamentos","Locação Pausada","Patrimônio",1,1,.F.)	
oExcel:AddColumn("Equipamentos","Locação Pausada","Num.Série",1,1,.F.)	
oExcel:AddColumn("Equipamentos","Locação Pausada","Dt.Entrega",1,4,.F.)	
oExcel:AddColumn("Equipamentos","Locação Pausada","Responsável",1,1,.F.)
oExcel:AddColumn("Equipamentos","Locação Pausada","Diretoria",1,1,.F.)
oExcel:AddColumn("Equipamentos","Locação Pausada","Gerência Geral",1,1,.F.)
oExcel:AddColumn("Equipamentos","Locação Pausada","Gerência de Área",1,1,.F.)
oExcel:AddColumn("Equipamentos","Locação Pausada","Coordenação",1,1,.F.)
oExcel:AddColumn("Equipamentos","Locação Pausada","Supervisão",1,1,.F.)
		
For nX := 1 to Len(aMovimento)
	oExcel:AddRow("Equipamentos","Locação Pausada",{;
		aMovimento[nX,1],;
		aMovimento[nX,2],;
		aMovimento[nX,3],;
		aMovimento[nX,4],;
		aMovimento[nX,5],;
		aMovimento[nX,6],;
		aMovimento[nX,7],;
		aMovimento[nX,8],;
		aMovimento[nX,9],;
		aMovimento[nX,10],;
		aMovimento[nX,11],;
		aMovimento[nX,12],;
		aMovimento[nX,13]})
Next nX

oExcel:Activate()

oExcel:GetXMLFile(cDirDocs+"\Pausados.xml")

CpyS2T(cDirDocs+"\Pausados.xml" , cPath, .T.)

If !ApOleClient("MsExcel")
	MsgAlert("MsExcel não instalado.")
	Return
EndIf

oExcelApp := MsExcel():New()
oExcelApp:WorkBooks:Open(cPath+"Pausados.xml")
oExcelApp:SetVisible(.T.)

Return
