#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

Static _cModel   := "CADZ42MVC"
Static _cFunc    := "CADZ42"        
Static _cTitulo  := "QQP - Lançamentos "

User function CADZ42()
   
Local aButtons  := {}										         //-- Rotinas ViewDef   
   
   //-- Mantenho apenas o botao CANCELAR e CONFIRMAR
   aButtons := {{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.T.,Nil},{.T.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil},{.F.,Nil}} //"Confirmar"###"Fechar"

   FWExecView(_cTitulo,_cFunc,MODEL_OPERATION_UPDATE,,,,0,aButtons) 

Return nil

Static Function ModelDef()

Local oModel   := Nil
Local oStTmp   := FWFormStruct(1, 'Z43') //FWFormModelStruct():New()
Local oStFilho := FWFormStruct(1, 'Z42')
Local aZ42Rel  := {}
	
	//Adiciona a tabela na estrutura tempor?ria
	//oStTmp:AddTable('Z43', {'Z43_PROJET','Z43_OBRA','Z43_NUMQQP','Z43_DTINI','Z43_DTFIM','Z43_VLGOB','Z43_OBS'}, "Cabecalho")
	/*	
	//Adiciona o campo de Descriç?o
	oStTmp:AddField(;
	"Projeto",;                                                                 // [01]  C   Titulo do campo
	"Projeto",;                                                                 // [02]  C   ToolTip do campo
	"Z43_PROJET",;                                                                 // [03]  C   Id do Field
	"C",;                                                                         // [04]  C   Tipo do campo
	TamSX3("Z43_PROJET")[1],;                                                      // [05]  N   Tamanho do campo
	0,;                                                                           // [06]  N   Decimal do campo
	Nil,;                                                                         // [07]  B   Code-block de validaç?o do campo
	Nil,;                                                                         // [08]  B   Code-block de validaç?o When do campo
	{},;                                                                          // [09]  A   Lista de valores permitido do campo
	.T.,;                                                                         // [10]  L   Indica se o campo tem preenchimento obrigat?rio
	FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,Z43->Z43_PROJET,FP0->FP0_PROJET)" ),;   // [11]  B   Code-block de inicializacao do campo
	.F.,;                                                                         // [12]  L   Indica se trata-se de um campo chave
	.T.,;                                                                         // [13]  L   Indica se o campo pode receber valor em uma operaç?o de update.
	.F.)                                                                          // [14]  L   Indica se o campo é virtual
				
	oStTmp:AddField(;
	"Obra",;                                                                      // [01]  C   Titulo do campo
	"Obra",;                                                                      // [02]  C   ToolTip do campo
	"Z43_OBRA",;                                                              	  // [03]  C   Id do Field
	"C",;                                                                         // [04]  C   Tipo do campo
	TamSX3("Z43_OBRA")[1],;                                                       // [05]  N   Tamanho do campo
	0,;                                                                           // [06]  N   Decimal do campo
	Nil,;                                                                         // [07]  B   Code-block de validaç?o do campo
	Nil,;                                                                         // [08]  B   Code-block de validaç?o When do campo
	{},;                                                                          // [09]  A   Lista de valores permitido do campo
	.T.,;                                                                         // [10]  L   Indica se o campo tem preenchimento obrigat?rio
	Nil,;   																	  // [11]  B   Code-block de inicializacao do campo
	.F.,;                                                                         // [12]  L   Indica se trata-se de um campo chave
	.T.,;                                                                         // [13]  L   Indica se o campo pode receber valor em uma operaç?o de update.
	.F.)                                                                          // [14]  L   Indica se o campo é virtual				

	oStTmp:AddField(;
	"Nr. QQP",;                                                                   // [01]  C   Titulo do campo
	"NRQQP",;                                                                     // [02]  C   ToolTip do campo
	"Z43_NUMQQP",;                                                                // [03]  C   Id do Field
	"C",;                                                                         // [04]  C   Tipo do campo
	TamSX3("Z43_NUMQQP")[1],;                                                     // [05]  N   Tamanho do campo
	0,;                                                                           // [06]  N   Decimal do campo
	Nil,;                                                                         // [07]  B   Code-block de validaç?o do campo
	Nil,;                                                                         // [08]  B   Code-block de validaç?o When do campo
	{},;                                                                          // [09]  A   Lista de valores permitido do campo
	.T.,;                                                                         // [10]  L   Indica se o campo tem preenchimento obrigat?rio
	Nil,;   																	  // [11]  B   Code-block de inicializacao do campo
	.F.,;                                                                         // [12]  L   Indica se trata-se de um campo chave
	.T.,;                                                                         // [13]  L   Indica se o campo pode receber valor em uma operaç?o de update.
	.F.)                                                                          // [14]  L   Indica se o campo é virtual				

	oStTmp:AddField(;
	"Data Inicio",;                                                               // [01]  C   Titulo do campo
	"Data Inicio",;                                                               // [02]  C   ToolTip do campo
	"Z43_DTINI",;                                                                 // [03]  C   Id do Field
	"D",;                                                                         // [04]  C   Tipo do campo
	TamSX3("Z43_DTINI")[1],;                                                      // [05]  N   Tamanho do campo
	0,;                                                                           // [06]  N   Decimal do campo
	Nil,;                                                                         // [07]  B   Code-block de validaç?o do campo
	Nil,;                                                                         // [08]  B   Code-block de validaç?o When do campo
	{},;                                                                          // [09]  A   Lista de valores permitido do campo
	.T.,;                                                                         // [10]  L   Indica se o campo tem preenchimento obrigat?rio
	Nil,;   																	  // [11]  B   Code-block de inicializacao do campo
	.F.,;                                                                         // [12]  L   Indica se trata-se de um campo chave
	.T.,;                                                                         // [13]  L   Indica se o campo pode receber valor em uma operaç?o de update.
	.F.)                                                                          // [14]  L   Indica se o campo é virtual				

	oStTmp:AddField(;
	"Data Fim",;    	                                                          // [01]  C   Titulo do campo
	"Data Fim",; 	                                                              // [02]  C   ToolTip do campo
	"Z43_DTFIM",;                                                                 // [03]  C   Id do Field
	"D",;                                                                         // [04]  C   Tipo do campo
	TamSX3("Z43_DTFIM")[1],;                                                      // [05]  N   Tamanho do campo
	0,;                                                                           // [06]  N   Decimal do campo
	Nil,;                                                                         // [07]  B   Code-block de validaç?o do campo
	Nil,;                                                                         // [08]  B   Code-block de validaç?o When do campo
	{},;                                                                          // [09]  A   Lista de valores permitido do campo
	.T.,;                                                                         // [10]  L   Indica se o campo tem preenchimento obrigat?rio
	Nil,;   																	  // [11]  B   Code-block de inicializacao do campo
	.F.,;                                                                         // [12]  L   Indica se trata-se de um campo chave
	.T.,;                                                                         // [13]  L   Indica se o campo pode receber valor em uma operaç?o de update.
	.F.)                                                                          // [14]  L   Indica se o campo é virtual				

	oStTmp:AddField(;
	"Vl Global Ctr",;  	                                                          // [01]  C   Titulo do campo
	"Vl Global Ctr",;                                                             // [02]  C   ToolTip do campo
	"Z43_VLGOB",;                                                                 // [03]  C   Id do Field
	"N",;                                                                         // [04]  C   Tipo do campo
	TamSX3("Z43_VLGOB")[1],;                                                      // [05]  N   Tamanho do campo
	2,;                                                                           // [06]  N   Decimal do campo
	Nil,;                                                                         // [07]  B   Code-block de validaç?o do campo
	Nil,;                                                                         // [08]  B   Code-block de validaç?o When do campo
	{},;                                                                          // [09]  A   Lista de valores permitido do campo
	.T.,;                                                                         // [10]  L   Indica se o campo tem preenchimento obrigat?rio
	Nil,;   																	  // [11]  B   Code-block de inicializacao do campo
	.F.,;                                                                         // [12]  L   Indica se trata-se de um campo chave
	.T.,;                                                                         // [13]  L   Indica se o campo pode receber valor em uma operaç?o de update.
	.F.)                                                                          // [14]  L   Indica se o campo é virtual				

	oStTmp:AddField(;
	"Obs",;    			                                                          // [01]  C   Titulo do campo
	"Obs",;		 	                                                              // [02]  C   ToolTip do campo
	"Z43_OBS",; 	                                                              // [03]  C   Id do Field
	"C",;                                                                         // [04]  C   Tipo do campo
	TamSX3("Z43_OBS")[1],;	                                                      // [05]  N   Tamanho do campo
	0,;                                                                           // [06]  N   Decimal do campo
	Nil,;                                                                         // [07]  B   Code-block de validaç?o do campo
	Nil,;                                                                         // [08]  B   Code-block de validaç?o When do campo
	{},;                                                                          // [09]  A   Lista de valores permitido do campo
	.T.,;                                                                         // [10]  L   Indica se o campo tem preenchimento obrigat?rio
	Nil,;   																	  // [11]  B   Code-block de inicializacao do campo
	.F.,;                                                                         // [12]  L   Indica se trata-se de um campo chave
	.T.,;                                                                         // [13]  L   Indica se o campo pode receber valor em uma operaç?o de update.
	.F.)                                                                          // [14]  L   Indica se o campo é virtual				

	*/
	//Setando as propriedades na grid, o inicializador da Filial e Tabela, para n?o dar mensagem de coluna vazia
	//oStTmp:SetProperty('Z42_PROJET', MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, '"*"'))
	//oStFilho:SetProperty('PZ4_PASS', MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, '"***"'))

    
    //Criando o FormModel, adicionando o Cabeçalho e Grid
	oModel := MPFormModel():New(_cModel, , {|oModel| FXZ4206Ok(oModel)},{|oModel| CommitZ42(oModel)})
	oModel:AddFields("FORMCAB",/*cOwner*/,oStTmp,/*bPre*/,/*bPost*/,{|oModel|CargaZ42(oModel)})
	oModel:AddGrid('Z42DETAIL'	,'FORMCAB'	,oStFilho, , , , ,{|oModel|CargaZ42(oModel)})
	
	//Adiciona o relacionamento de Filho, Pai
	aAdd(aZ42Rel, {'Z42_FILIAL' , 'Z43_FILIAL'} )
	aAdd(aZ42Rel, {'Z42_PROJET' , 'Z43_PROJET'} )
	aAdd(aZ42Rel, {'Z42_NUMQQP' , 'Z43_NUMQQP'} )

	//Criando o relacionamento
	oModel:SetRelation('Z42DETAIL', aZ42Rel, Z42->(IndexKey(1)))
	
	//Setando o campo ?nico da grid para n?o ter repetiç?o
//	oModel:GetModel('Z42DETAIL'):SetUniqueLine({"Z42_PROJET"})
	
	
	//Setando outras informaç?es do Modelo de Dados
	oModel:SetDescription(_cTitulo)
	oModel:SetPrimaryKey({})
	oModel:GetModel("FORMCAB"):SetDescription("Formul?rio do Cadastro "+_cTitulo)
	
	
Return oModel

Static Function ViewDef()

Local oModel     := ModelDef()							//-- Obtem ModelDef
Local oView      := FWFormView():New()				//-- Retorno ViewDef   
Local oStTmp    := FWFormStruct(2, 'Z43')//FWFormViewStruct():New()
Local oStFilho  := FWFormStruct(2, 'Z42')
	/*
	oStTmp:AddField(;
	"Z43_PROJET",;                // [01]  C   Nome do Campo
	"01",;                      // [02]  C   Ordem
	"Projeto",;                  // [03]  C   Titulo do campo
	X3Descric('Z43_PROJET'),;    // [04]  C   Descricao do campo
	Nil,;                       // [05]  A   Array com Help
	"C",;                       // [06]  C   Tipo do campo
	X3Picture("Z43_PROJET"),;    // [07]  C   Picture
	Nil,;                       // [08]  B   Bloco de PictTre Var
	Nil,;                       // [09]  C   Consulta F3
	Iif(INCLUI, .T., .F.),;     // [10]  L   Indica se o campo é alteravel
	Nil,;                       // [11]  C   Pasta do campo
	Nil,;                       // [12]  C   Agrupamento do campo
	Nil,;                       // [13]  A   Lista de valores permitido do campo (Combo)
	Nil,;                       // [14]  N   Tamanho maximo da maior opç?o do combo
	Nil,;                       // [15]  C   Inicializador de Browse
	Nil,;                       // [16]  L   Indica se o campo é virtual
	Nil,;                       // [17]  C   Picture Variavel
	Nil)                        // [18]  L   Indica pulo de linha ap?s o campo


	oStTmp:AddField(;
	"Z43_OBRA",;                // [01]  C   Nome do Campo
	"02",;                      // [02]  C   Ordem
	"Obra",;                    // [03]  C   Titulo do campo
	X3Descric('Z43_OBRA'),;     // [04]  C   Descricao do campo
	Nil,;                       // [05]  A   Array com Help
	"C",;                       // [06]  C   Tipo do campo
	X3Picture("Z43_OBRA"),;     // [07]  C   Picture
	Nil,;                       // [08]  B   Bloco de PictTre Var
	Nil,;                       // [09]  C   Consulta F3
	.T.,;					     // [10]  L   Indica se o campo é alteravel
	Nil,;                       // [11]  C   Pasta do campo
	Nil,;                       // [12]  C   Agrupamento do campo
	Nil,;                       // [13]  A   Lista de valores permitido do campo (Combo)
	Nil,;                       // [14]  N   Tamanho maximo da maior opç?o do combo
	Nil,;                       // [15]  C   Inicializador de Browse
	Nil,;                       // [16]  L   Indica se o campo é virtual
	Nil,;                       // [17]  C   Picture Variavel
	Nil)                        // [18]  L   Indica pulo de linha ap?s o campo

	oStTmp:AddField(;
	"Z43_NUMQQP",;                // [01]  C   Nome do Campo
	"03",;                      // [02]  C   Ordem
	"Nr. QQP",;                    // [03]  C   Titulo do campo
	X3Descric('Z43_NUMQQP'),;     // [04]  C   Descricao do campo
	Nil,;                       // [05]  A   Array com Help
	"C",;                       // [06]  C   Tipo do campo
	X3Picture("Z43_NUMQQP"),;     // [07]  C   Picture
	Nil,;                       // [08]  B   Bloco de PictTre Var
	Nil,;                       // [09]  C   Consulta F3
	.T.,;					     // [10]  L   Indica se o campo é alteravel
	Nil,;                       // [11]  C   Pasta do campo
	Nil,;                       // [12]  C   Agrupamento do campo
	Nil,;                       // [13]  A   Lista de valores permitido do campo (Combo)
	Nil,;                       // [14]  N   Tamanho maximo da maior opç?o do combo
	Nil,;                       // [15]  C   Inicializador de Browse
	Nil,;                       // [16]  L   Indica se o campo é virtual
	Nil,;                       // [17]  C   Picture Variavel
	Nil)                        // [18]  L   Indica pulo de linha ap?s o campo


	oStTmp:AddField(;
	"Z43_DTINI",;               // [01]  C   Nome do Campo
	"04",;                      // [02]  C   Ordem
	"Data Inicial",;            // [03]  C   Titulo do campo
	X3Descric('Z43_DTINI'),;    // [04]  C   Descricao do campo
	Nil,;                       // [05]  A   Array com Help
	"D",;                       // [06]  C   Tipo do campo
	X3Picture("Z43_DTINI"),;    // [07]  C   Picture
	Nil,;                       // [08]  B   Bloco de PictTre Var
	Nil,;                       // [09]  C   Consulta F3
	.T.,;					     // [10]  L   Indica se o campo é alteravel
	Nil,;                       // [11]  C   Pasta do campo
	Nil,;                       // [12]  C   Agrupamento do campo
	Nil,;                       // [13]  A   Lista de valores permitido do campo (Combo)
	Nil,;                       // [14]  N   Tamanho maximo da maior opç?o do combo
	Nil,;                       // [15]  C   Inicializador de Browse
	Nil,;                       // [16]  L   Indica se o campo é virtual
	Nil,;                       // [17]  C   Picture Variavel
	Nil)                        // [18]  L   Indica pulo de linha ap?s o campo

	oStTmp:AddField(;
	"Z43_DTFIM",;               // [01]  C   Nome do Campo
	"05",;                      // [02]  C   Ordem
	"Data FInal",;              // [03]  C   Titulo do campo
	X3Descric('Z43_DTFIM'),;    // [04]  C   Descricao do campo
	Nil,;                       // [05]  A   Array com Help
	"D",;                       // [06]  C   Tipo do campo
	X3Picture("Z43_DTFIM"),;    // [07]  C   Picture
	Nil,;                       // [08]  B   Bloco de PictTre Var
	Nil,;                       // [09]  C   Consulta F3
	.T.,;					     // [10]  L   Indica se o campo é alteravel
	Nil,;                       // [11]  C   Pasta do campo
	Nil,;                       // [12]  C   Agrupamento do campo
	Nil,;                       // [13]  A   Lista de valores permitido do campo (Combo)
	Nil,;                       // [14]  N   Tamanho maximo da maior opç?o do combo
	Nil,;                       // [15]  C   Inicializador de Browse
	Nil,;                       // [16]  L   Indica se o campo é virtual
	Nil,;                       // [17]  C   Picture Variavel
	Nil)                        // [18]  L   Indica pulo de linha ap?s o campo

	oStTmp:AddField(;
	"Z43_VLGOB",;               // [01]  C   Nome do Campo
	"06",;                      // [02]  C   Ordem
	"Vl Global",;              // [03]  C   Titulo do campo
	X3Descric('Z43_VLGOB'),;    // [04]  C   Descricao do campo
	Nil,;                       // [05]  A   Array com Help
	"N",;                       // [06]  C   Tipo do campo
	X3Picture("Z43_VLGOB"),;    // [07]  C   Picture
	Nil,;                       // [08]  B   Bloco de PictTre Var
	Nil,;                       // [09]  C   Consulta F3
	Iif(INCLUI, .T., .F.),;     // [10]  L   Indica se o campo é alteravel
	Nil,;                       // [11]  C   Pasta do campo
	Nil,;                       // [12]  C   Agrupamento do campo
	Nil,;                       // [13]  A   Lista de valores permitido do campo (Combo)
	Nil,;                       // [14]  N   Tamanho maximo da maior opç?o do combo
	Nil,;                       // [15]  C   Inicializador de Browse
	Nil,;                       // [16]  L   Indica se o campo é virtual
	Nil,;                       // [17]  C   Picture Variavel
	Nil)                        // [18]  L   Indica pulo de linha ap?s o campo

	oStTmp:AddField(;
	"Z43_OBS",;	                // [01]  C   Nome do Campo
	"07",;                      // [02]  C   Ordem
	"Obs",;			            // [03]  C   Titulo do campo
	X3Descric('Z43_OBS'),;      // [04]  C   Descricao do campo
	Nil,;                       // [05]  A   Array com Help
	"C",;                       // [06]  C   Tipo do campo
	X3Picture("Z43_OBS"),;	    // [07]  C   Picture
	Nil,;                       // [08]  B   Bloco de PictTre Var
	Nil,;                       // [09]  C   Consulta F3
	.T.,;					     // [10]  L   Indica se o campo é alteravel
	Nil,;                       // [11]  C   Pasta do campo
	Nil,;                       // [12]  C   Agrupamento do campo
	Nil,;                       // [13]  A   Lista de valores permitido do campo (Combo)
	Nil,;                       // [14]  N   Tamanho maximo da maior opç?o do combo
	Nil,;                       // [15]  C   Inicializador de Browse
	Nil,;                       // [16]  L   Indica se o campo é virtual
	Nil,;                       // [17]  C   Picture Variavel
	Nil)                        // [18]  L   Indica pulo de linha ap?s o campo
	*/

	//Criando a view que ser? o retorno da funç?o e setando o modelo da rotina
	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("VIEW_CAB", oStTmp, "FORMCAB")
	oView:AddGrid('VIEW_Z42' ,oStFilho,'Z42DETAIL')
	
	//Setando o dimensionamento de tamanho
	oView:CreateHorizontalBox('CABEC',40)
	oView:CreateHorizontalBox('GRID',60)
	
	//Amarrando a view com as box
	oView:SetOwnerView('VIEW_CAB','CABEC')
	oView:SetOwnerView('VIEW_Z42','GRID')
	
	//Habilitando t?tulo
	oView:EnableTitleView('VIEW_CAB','Projeto')
	oView:EnableTitleView('VIEW_Z42','Lançamentos')
	
	//Tratativa padr?o para fechar a tela
	oView:SetCloseOnOk({||.T.})
	
	//Remove os campos de Filial e Tabela da Grid
	oStFilho:RemoveField('Z42_FILIAL')
	oStFilho:RemoveField('Z42_PROJET')
	oStFilho:RemoveField('Z42_OBRA')
	oStFilho:RemoveField('Z42_NUMQQP')
	
	// Incrementa
   oView:AddIncrementField( 'VIEW_Z42', 'Z42_ITEM' )

Return oView

Static Function  CommitZ42(oModel)
	
	Local oModelDad  	:= FWModelActive()
	//Local nOpc       	:= oModelDad:GetOperation()
	Local oModelGrid 	:= oModelDad:GetModel('Z42DETAIL')
	Local oModelCabec   := oModelDad:GetModel('FORMCAB')
	Local nCont   		:= 0

	DbSelectArea("Z43")
	DbSetOrder(1) //Z43_FILIAL+Z43_PROJET+Z43_NUMQQP
	If !DbSeek(FP0->FP0_FILIAL+FP0->FP0_PROJET+oModelCabec:GetValue("Z43_NUMQQP")) 
		RecLock("Z43",.T.)
			Z43->Z43_FILIAL := FP0->FP0_FILIAL
			Z43->Z43_PROJET := FP0->FP0_PROJET
			Z43->Z43_OBRA	:= oModelCabec:GetValue("Z43_OBRA")
			Z43->Z43_NUMQQP := oModelCabec:GetValue("Z43_NUMQQP")
			Z43->Z43_DTINI  := oModelCabec:GetValue("Z43_DTINI")
			Z43->Z43_DTFIM  := oModelCabec:GetValue("Z43_DTFIM")
			Z43->Z43_VLGOB  := oModelCabec:GetValue("Z43_VLGOB")
			Z43->Z43_OBS    := oModelCabec:GetValue("Z43_OBS")
		Z43->(MsUnlock())
	Else
		RecLock("Z43",.F.)
			Z43->Z43_OBRA	:= oModelCabec:GetValue("Z43_OBRA")
			Z43->Z43_NUMQQP := oModelCabec:GetValue("Z43_NUMQQP")
			Z43->Z43_DTINI  := oModelCabec:GetValue("Z43_DTINI")
			Z43->Z43_DTFIM  := oModelCabec:GetValue("Z43_DTFIM")
			Z43->Z43_VLGOB  := oModelCabec:GetValue("Z43_VLGOB")
			Z43->Z43_OBS    := oModelCabec:GetValue("Z43_OBS")
		Z43->(MsUnlock())	
	Endif


	DbSelectArea("Z42")
	DbSetOrder(1) //Z42_FILIAL+Z42_PROJET+Z42_NUMQQP+Z42_ITEM

	For nCont := 1 to oModelGrid:Length()

      //-- Posiciona linha do grid
      oModelGrid:GoLine(nCont)  

      //-- Ignora linhas deletadas 
      If oModelGrid:IsDeleted() 
         Loop
      EndIf
	  
	  If !DbSeek(FP0->FP0_FILIAL+FP0->FP0_PROJET+oModelGrid:GetValue("Z42_NUMQQP")+oModelGrid:GetValue("Z42_ITEM"))
	  	 RecLock("Z42",.T.)
            Z42->Z42_FILIAL	:= FP0->FP0_FILIAL
            Z42->Z42_PROJET	:= FP0->FP0_PROJET
            Z42->Z42_OBRA	:= oModelGrid:GetValue("Z42_OBRA")
			Z42->Z42_NUMQQP	:= oModelCabec:GetValue("Z43_NUMQQP")
            Z42->Z42_ITEM	:= oModelGrid:GetValue("Z42_ITEM")
			Z42->Z42_ITQQP	:= oModelGrid:GetValue("Z42_ITQQP")
            Z42->Z42_DESC	:= oModelGrid:GetValue("Z42_DESC")
            Z42->Z42_TPITEM	:= oModelGrid:GetValue("Z42_TPITEM")
            Z42->Z42_PRAZO	:= oModelGrid:GetValue("Z42_PRAZO")
            Z42->Z42_QTD	:= oModelGrid:GetValue("Z42_QTD")
            Z42->Z42_VLUNI	:= oModelGrid:GetValue("Z42_VLUNI") 
            Z42->Z42_VLTOT	:= oModelGrid:GetValue("Z42_VLTOT")
			Z42->Z42_VLGOB	:= oModelGrid:GetValue("Z42_VLGOB")
		 Z42->(MsUnlock())
	  Else
	  	 RecLock("Z42",.F.)
            Z42->Z42_OBRA	:= oModelGrid:GetValue("Z42_OBRA")
			Z42->Z42_NUMQQP	:= oModelCabec:GetValue("Z43_NUMQQP")
            Z42->Z42_ITEM	:= oModelGrid:GetValue("Z42_ITEM")
			Z42->Z42_ITQQP	:= oModelGrid:GetValue("Z42_ITQQP")
            Z42->Z42_DESC	:= oModelGrid:GetValue("Z42_DESC")
            Z42->Z42_TPITEM	:= oModelGrid:GetValue("Z42_TPITEM")
            Z42->Z42_PRAZO	:= oModelGrid:GetValue("Z42_PRAZO")
            Z42->Z42_QTD	:= oModelGrid:GetValue("Z42_QTD")
            Z42->Z42_VLUNI	:= oModelGrid:GetValue("Z42_VLUNI") 
            Z42->Z42_VLTOT	:= oModelGrid:GetValue("Z42_VLTOT")
			Z42->Z42_VLGLOB	:= oModelGrid:GetValue("Z42_VLGLOB")
		 Z42->(MsUnlock())
	  Endif
	Next Cont
	
	//fwformcommit(oModel)

Return .t.

Static Function FXZ4206Ok(oModel)
	
   Local aArea      := GetArea()
   Local lRet       := .T.
	//Local oModelDad  := FWModelActive()
	//Local nOpc       := oModelDad:GetOperation()
	//Local oModelGrid := oModelDad:GetModel('Z42DETAIL')
	
	RestArea(aArea)

Return lRet

/*
Rotina para lançamentos de dados do Orçamentos
@author Gines 
@since 27/11/2025
@version V12
@database MSSQL
*/
Static Function CargaZ42(oModel)

   Local cFilFP0 := FP0->FP0_FILIAL
   Local cPrjFP0 := FP0->FP0_PROJET
   Local aRet    := {}
   Local aDados  := {}
   Local aLoad   := {}													//-- Retorno funcao
   Local nCont   := 0													//-- Contador generico 

   //-- Coloco no Model Master, o codigo da Filial Corrente apenas para Carga
   If oModel:GetId() == "FORMCAB"
      _cWrk1 := GetNextAlias()

      If Select(_cWrk1) <> 0
         (_cWrk1)->(DbCloseArea())
      EndIf
      
      BeginSql Alias _cWrk1
               
         SELECT 
		 		Z43_FILIAL,
				Z43_PROJET,
				Z43_OBRA,
				Z43_NUMQQP,
				Z43_DTINI,
				Z43_DTFIM,
				Z43_VLGOB,
		 		ISNULL(CONVERT(VARCHAR(2024),CONVERT(VARBINARY(2024),Z43_OBS)),'') AS Z43_OBS
         FROM %Table:Z43% Z43
         WHERE 	Z43_FILIAL     = %Exp:cFilFP0%  AND
            	Z43.Z43_PROJET = %Exp:cPrjFP0%	AND
            	Z43.%NotDel%

      EndSql
               
      //Verifico e faço a transferencia via execauto
      If (_cWrk1)->(!Eof())
   		   AADD(aLoad, {(_cWrk1)->Z43_FILIAL,;
						(_cWrk1)->Z43_PROJET,;
			  		   	(_cWrk1)->Z43_OBRA,;
						(_cWrk1)->Z43_NUMQQP,;
						STOD((_cWrk1)->Z43_DTINI),;
						STOD((_cWrk1)->Z43_DTFIM),;
						(_cWrk1)->Z43_VLGOB,;
						(_cWrk1)->Z43_OBS;
					  })
	  Else
   		   AADD(aLoad, {FP0->FP0_FILIAL,;
						FP0->FP0_PROJET,;
			  		   	SPACE(03),;
						"0001",; //SPACE(04),;
						CTOD("  /  /  "),;
						CTOD("  /  /  "),;
						0,;
						SPACE(254);
					   })
	  Endif

   Else
      
      _cWrk := GetNextAlias()

      If Select(_cWrk) <> 0
         (_cWrk)->(DbCloseArea())
      EndIf
      
      BeginSql Alias _cWrk
               
         SELECT *
         FROM %Table:Z42% Z42
         WHERE 	Z42_FILIAL     = %Exp:cFilFP0%    AND
            	Z42.Z42_PROJET = %Exp:cPrjFP0%	AND
            	Z42.%NotDel%

      EndSql
               
      //Verifico e faço a transferencia via execauto
      If (_cWrk)->(!Eof())
         While (_cWrk)->(!Eof())
            AADD(aDados,{  (_cWrk)->Z42_FILIAL,;
                           (_cWrk)->Z42_PROJET,;
                           (_cWrk)->Z42_OBRA,;
						   (_cWrk)->Z42_NUMQQP,;  
                           (_cWrk)->Z42_ITEM,;
						   (_cWrk)->Z42_ITQQP,;  
                           (_cWrk)->Z42_DESC,;  
                           (_cWrk)->Z42_TPITEM,;
                           (_cWrk)->Z42_PRAZO,;
                           (_cWrk)->Z42_QTD,;   
                           (_cWrk)->Z42_VLUNI,; 
                           (_cWrk)->Z42_VLTOT,; 
						   (_cWrk)->Z42_VLGLOB;
                        })
            (_cWrk)->(DbSkip())
         Enddo
      Endif
      
      If Len(aDados) == 0
            AADD(aRet,{ FP0->FP0_FILIAL   		,;		//-- [01] Codigo d Filial
                        FP0->FP0_PROJET   		,;		//-- [02] Codigo do projeto
                        SPACE(03)               ,;		//-- [03] Obra
						IIF(ValType(Z43->Z43_NUMQQP) <> "C" .or. Empty(Alltrim(Z43->Z43_NUMQQP)), "0001", Z43->Z43_NUMQQP),;		//-- [04] Num. QQP
						"0001"         			,;		//-- [05] Item
						SPACE(06)     			,; 		//-- [06] Item QQP //
                        SPACE(254)     			,;		//-- [07] Descricao
                        ""	               		,;		//-- [08] Tipo de item
                        0              			,;		//-- [09] Prazo
                        0              			,;		//-- [10] Quantidade
                        0              			,;		//-- [11] Valor Unitario
                        0              			,;		//-- [12] Valor Total
						0              			;		//-- [13] Valor Global
                     })

      Else
         For nCont := 1 to Len(aDados)
            AADD(aRet,{ aDados[nCont][01]   		,;		//-- [01] Codigo da Filial
                        aDados[nCont][02]   		,;		//-- [02] Codigo do projeto
                        aDados[nCont][03]			,;		//-- [03] Obra
						aDados[nCont][04]			,;		//-- [04] Num QQp
                        aDados[nCont][05]			,;		//-- [05] Item
						aDados[nCont][06]			,;		//-- [06] Item QQP
                        aDados[nCont][07]			,;		//-- [07] Descricao
                        aDados[nCont][08]			,;		//-- [08] Tipo de item
                        aDados[nCont][09]			,;		//-- [09] Prazo
                        aDados[nCont][10]			,;		//-- [10] Quantidade
                        aDados[nCont][11]			,;		//-- [11] Valor Unitario
                        aDados[nCont][12]			,;		//-- [12] Valor Total                        
						aDados[nCont][13]			;		//-- [13] Valor Global                        
                     })
         Next nCont
      Endif            
      
      //-- Preenche dados de carga do Model
      For nCont := 1 to Len(aRet)
         AADD(aLoad,{0,aRet[nCont]})
      Next nCont
   
   EndIf

Return aLoad


User Function FXZ42TOT()

Local oModelDad  	:= FWModelActive()
Local oModelGrid 	:= oModelDad:GetModel('Z42DETAIL')
Local oModelCabec   := oModelDad:GetModel('FORMCAB')
Local nVlr    := 0
Local nVlrTot := 0
Local nCont   := 0

//PM=Prod.Mensal;LM=LicencaMensal;SM=Serv.Mensal;SA=Serv.Avulso;RS=Ressarc.;PA=Prod.Avulso
If oModelGrid:GetValue("Z42_TPITEM")$"PM/LM/SM"
	nVlr := oModelGrid:GetValue("Z42_PRAZO")*oModelGrid:GetValue("Z42_VLTOT") 
Else
	nVlr := oModelGrid:GetValue("Z42_VLTOT")
Endif

For nCont := 1 to oModelGrid:Length()
      //-- Posiciona linha do grid
      oModelGrid:GoLine(nCont)  

      //-- Ignora linhas deletadas 
      If oModelGrid:IsDeleted() 
         Loop
      EndIf

	  nVlrTot+=oModelGrid:GetValue("Z42_VLGLOB")
Next nCont

nVlrTot+=nVlr	
oModelCabec:SetValue("Z43_VLGOB",nVlrTot)

Return nVlr
