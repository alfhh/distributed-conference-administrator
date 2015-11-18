% Tarea 6 - Erlang
% Alfredo Hinojosa Huerta A01036053
% Sergio Cordero Barrera A01191167
% Luis Juan Sanchez Padilla A01183634
% Rodolfo Cantu Ortiz A01036042
%
% --------------------------------------------------------------- Meta
-module(tarea6).
-export([inicia_servidor/0, servidor/0, registra_conferencia/5, conferencia/6, conferencias_inscritas/1, asistentes_inscritos/1, desinscribe_conferencia/2,
	registra_asistente/2, asistente/3, lista_asistentes/0, lista_conferencias/0, inscribe_conferencia/2, elimina_asistente/1]).

%% cambia la funcion acontinuacion para que refleje el nombre del
%% nodo servidor (para ver tu nombre corre en UNIX con el comando
%% 'sudo erl -sname NOMBRE' donde NOMBRE es el nombre que quieres
%% usar. Acontinuacion, el nombre estara antes del numero de linea
%% a ejecutar.
nodo_servidor() ->
  servidor@localhost.

%% el proceso que corre de administracion
%% las listas tienen el formato de:
%%
%%  asistente: [#{clave => CLAVE,
%%                nombre => NOMBRE,
%%                conferencias => [C1, C2, C3, ...]}...]
%%
%%  conferencia: [#{conferencia => CONFERENCIA,
%%                  titulo => TITULO,
%%                  conferencista => CONFERENCISTA,
%%                  horario => HORARIO,
%%                  cupo => CUPO,
%%                  asistentes => [A1, A2, A3, ...]}...]
servidor() ->
  process_flag(trap_exit, true), % el hijo manda se reinicia si se cae
  servidor([], []). % llama al servidor con 2 listas vacias

servidor(L_Asistentes, L_Conferencias) ->
  receive

 	{From, Conferencia, registra_c} -> % agregar una nueva conferencia
		io:format("nueva conf ~p ~n", [{From, Conferencia}]),
 		Nueva_Conferencias = server_nuevaConferencia(From, Conferencia, L_Conferencias),
 		servidor(L_Asistentes, Nueva_Conferencias);

 	{From, registra_a, Asistente, Nombre} -> % agregar un nuevo asistente
 		io:format("estoy aqui ~n", []),
 		Nueva_Asistentes = server_nuevoAsistente(From, Asistente, Nombre, L_Asistentes),
 		servidor(Nueva_Asistentes, L_Conferencias);

 	{From, lista_conferencias} -> % lista todas las conferencias con los asistentes inscritos
      		server_pide_conferencia(L_Conferencias, [], From),
	 		servidor(L_Asistentes, L_Conferencias);

 	{From, lista_a} -> % lista todos los asistentes con las conferencias a las que estan inscritos
	    From ! {lista, L_Asistentes},
	 		servidor(L_Asistentes, L_Conferencias);

	 {From, elimina_a, Asistente} -> % Asistente debe ser eliminado!
		io:format("estoy aqui ~n", []),
		Elimina_asistente = server_eliminaAsistente(Asistente, L_Asistentes, []),
		case Elimina_asistente == L_Asistentes of
		    	true ->
		    		From ! {servidor, asistente_inexistente},
		    		servidor(Elimina_asistente, L_Conferencias);
		    	false ->
		    		From ! {servidor, asistente_eliminado},
		    		servidor(Elimina_asistente, L_Conferencias)
		end;	

	{From, Asistente, Conferencia, desinscribe} -> %Asistente a desinscribirse de la conferencia
		io:format("Desinscribirse ~n", []),
		ExisteAsistente = server_checaExistenciaAsistente(Asistente, L_Asistentes),
		ExisteConferencia = lists:keymember(Conferencia, 2, L_Conferencias),
		io:format("existentes conf ~p ~p ~n", [ExisteAsistente, ExisteConferencia]),
		case ExisteAsistente and ExisteConferencia of
			false ->
				server_inexistenteAsistenteConferencia(From, ExisteAsistente, ExisteConferencia),
				servidor(L_Asistentes, L_Conferencias);
			true ->
				Nueva_Asistentes = server_desinscribirAsistenteConferencia(From, Asistente, Conferencia, L_Asistentes),
				server_desinscribirConferenciaAsistente(Asistente, Conferencia, L_Conferencias),
				From ! {servidor, asistente_eliminado},
				servidor(Nueva_Asistentes, L_Conferencias)				
		end;

 	%{From, conferencias_de, Asistente} -> % imprimir las conferencias de Asistente
 	% 	Resultado = server_conferenciasDe(From, Asistente, L_Asistentes),
 	% 	io:format("las conferencias son: ~p~n", [Resultado])

	{From, asistentes_en, Conferencia} -> % imprimir las conferencias de Asistente
	 	Resultado = server_asistentesEn(From, Conferencia, L_Asistentes, L_Conferencias),
 	 	io:format("los asistentes son: ~p~n", [Resultado]),
		servidor(L_Asistentes, L_Conferencias);
	
	{From, Asistente, Conferencia, inscribe_c} ->
		ExisteAsistente = server_checaExistenciaAsistente(Asistente, L_Asistentes),
		ExisteConferencia = lists:keymember(Conferencia, 2, L_Conferencias),
		io:format("existentes conf ~p ~p ~n", [ExisteAsistente, ExisteConferencia]),
		case ExisteAsistente and ExisteConferencia of
			false ->
				server_inexistenteAsistenteConferencia(From, ExisteAsistente, ExisteConferencia),
				servidor(L_Asistentes, L_Conferencias);
			true ->
				CupoAsistente = server_checaCupoAsistente(Asistente, L_Asistentes),
				CupoConferencia = server_checaCupoConferencia(Conferencia, L_Conferencias),
				EstaInscrito = server_checaExistenciaInscripcion(Asistente, Conferencia, L_Asistentes),
				io:format("cupo conf ~p ~p ~p ~n", [CupoAsistente, CupoConferencia, EstaInscrito]),
				case CupoAsistente and CupoConferencia and not EstaInscrito of
					false ->
						server_cupollenoAsistenteConferencia(From, CupoAsistente, CupoConferencia, EstaInscrito),
						servidor(L_Asistentes, L_Conferencias);
					true ->	
						io:format("listas anteriores ~p ~p ~n", [L_Asistentes, L_Conferencias]),
						From ! {servidor, inscribiendo_asistente_en_conferencia},
						Nueva_Asistentes = server_inscribirAsistenteConferencia(From, Asistente, Conferencia, L_Asistentes),
						server_inscribirConferenciaAsistente(Asistente, Conferencia, L_Conferencias),
						io:format("nuevas listas ~p ~p ~n", [Nueva_Asistentes, L_Conferencias]),
						servidor(Nueva_Asistentes, L_Conferencias)
				end
		end			

  end.

%Busca el atomo de un asistente en la lista de asistentes
server_buscarAsistente(_, []) ->
	[];
server_buscarAsistente(Asistente, L_Asistentes) ->
	[MapAsistente | Rest] = L_Asistentes,
	%io:format("~p == ~p ~n", [MapAsistente, Asistente]),
	case maps:get("clave",MapAsistente) == Asistente of
		true ->
			maps:remove("conferencias", MapAsistente);
		false -> 
			server_buscarAsistente(Asistente, Rest)
		end. 

%Obtiene los datos de los asistentes con la lista de atomos de la conferencia
server_obtenerAsistentes([], _) ->
	[];
server_obtenerAsistentes(Asistentes, L_Asistentes) ->
	%io:format("Asistentes en conferencia ~p~n", [Asistentes]),
	case Asistentes of
		[Asistente, Rest] ->
			[server_buscarAsistente(Asistente, L_Asistentes) | server_obtenerAsistentes(Rest, L_Asistentes)];
		[Asistente]->
			[server_buscarAsistente(Asistente, L_Asistentes)]
	end.
	

%Obtiene los datos de los asistentes de una conferencia
server_asistentesEn(From, Conferencia, L_Asistentes, L_Conferencias) ->
	case lists:keysearch(Conferencia, 2, L_Conferencias) of
		false ->
			io:format("server_inscribirConferenciaAsistente deberia de encotrar algo", []),
			false;
		{value, {PiDConf, Conferencia}} ->
			PiDConf ! {self(), asistentes_en},
			receive
				{asistentes_en, Asistentes} -> % Normal response
					io:format("Asistentes en conferencia ~p~n", [Asistentes]),
					From ! {asistentes_en, server_obtenerAsistentes(Asistentes, L_Asistentes)},
					server_obtenerAsistentes(Asistentes, L_Asistentes)
				after 5000 ->
					io:format("No response from conferencia~n", [])
			end
	end.

%Checa si un asistente ya esta inscrito en una conferencia
server_checaExistenciaInscripcion(_, _, []) ->
	io:format("server_checaExistenciaInscripcion no debio de haber llegado a una lista vacia", []),
	false;
server_checaExistenciaInscripcion(Asistente, Conferencia, L_Asistentes) ->
	[MapAsistente | Rest] = L_Asistentes,
	%io:format("~p == ~p ~n", [MapAsistente, Asistente]),
	case maps:get("clave",MapAsistente) == Asistente of
		true ->
			case maps:get("conferencias",MapAsistente) of
				[] -> 
					false;
				ListaConferencia ->
					io:format("conferencias del asistente: ~p ~n", [ListaConferencia]),
					lists:any(fun(X) -> X == Conferencia end, ListaConferencia)
				end;
		false -> 
			server_checaExistenciaInscripcion(Asistente, Conferencia, Rest)
		end. 

%Manda a inscribir el asistente en la conferencia
server_inscribirConferenciaAsistente(Asistente, Conferencia, L_Conferencias) ->
	case lists:keysearch(Conferencia, 2, L_Conferencias) of
		false ->
			io:format("server_inscribirConferenciaAsistente deberia de encotrar algo", []),
			false;
		{value, {PiDConf, Conferencia}} ->
			PiDConf ! {self(), registrar_asistente, Asistente},
			receive
				{registrar_asistente, What} -> % Normal response
						io:format("Se inscribio asistente ~p~n", [What])
				after 5000 ->
					io:format("No response from conferencia~n", [])
			end
	end.

%Manda a desdesinscribir el asistente en la conferencia
server_desinscribirConferenciaAsistente(Asistente, Conferencia, L_Conferencias) ->
	case lists:keysearch(Conferencia, 2, L_Conferencias) of
		false ->
			io:format("server_desinscribirConferenciaAsistente deberia de encotrar algo", []),
			false;
		{value, {PiDConf, Conferencia}} ->
			PiDConf ! {self(), desinscribir_asistente, Asistente},
			receive
				{desinscribir_asistente, What} -> % Normal response
						io:format("Se desinscribio asistente ~p~n", [What])
				after 5000 ->
					io:format("No response from conferencia~n", [])
			end
	end.


%Checa si la conferencia ya tiene el cupo limite
server_checaCupoConferencia(Conferencia, L_Conferencias) ->
	case lists:keysearch(Conferencia, 2, L_Conferencias) of
		false ->
			io:format("server_checaCupoConferencia deberia de encotrar algo", []),
			false;
		{value, {PiDConf, Conferencia}} ->
			PiDConf ! {self(), checar_cupo},
		receive
			{checar_cupo, What} -> % Normal response
				io:format("checar cupo de la conferencia ~p~n", [What]),
				What
		after 5000 ->
			io:format("No response from conferencia~n", [])
		end
	end.
			

%Checa si al asistente ya tiene 3 conferencias registradas
server_checaCupoAsistente(_, []) ->
	io:format("server_checaCupoAsistente no debio de haber llegado a una lista vacia", []),
	false;
server_checaCupoAsistente(Asistente, L_Asistentes) ->
	[MapAsistente | Rest] = L_Asistentes,
	%io:format("~p == ~p ~n", [MapAsistente, Asistente]),
	case maps:get("clave",MapAsistente) == Asistente of
		true ->
			case maps:get("conferencias",MapAsistente) of
				[] -> 
					true;
				ListaConferencia ->
					io:format("conferencias del asistente: ~p ~n", [ListaConferencia]),
					Conferencias = length(ListaConferencia),
					Conferencias < 3
				end;
		false -> 
			server_checaCupoAsistente(Asistente, Rest)
		end. 

%Agrega una conferencia a las inscritas del asistente
server_desinscribirAsistenteConferencia(_, _, _, []) ->
	io:format("server_inscribirAsistenteConferencia no debio de haber llegado a una lista vacia", []),
	[];
server_desinscribirAsistenteConferencia(From, Asistente, Conferencia, L_Asistentes) ->
	[MapAsistente | Rest] = L_Asistentes,
	%io:format("~p == ~p ~n", [MapAsistente, Asistente]),
	case maps:get("clave",MapAsistente) == Asistente of
		true ->
			io:format("~p - ~p = ~p~n", [maps:get("conferencias",MapAsistente), Conferencia,
				lists:delete(Conferencia ,maps:get("conferencias",MapAsistente))]),
			MapNuevoAsistente = maps:update("conferencias", lists:delete(Conferencia ,maps:get("conferencias",MapAsistente)), MapAsistente),
			[MapNuevoAsistente | Rest];
		false -> 
			[MapAsistente | server_desinscribirAsistenteConferencia(From, Asistente, Conferencia, Rest)]
		end. 


%Agrega una conferencia a las inscritas del asistente
server_inscribirAsistenteConferencia(_, _, _, []) ->
	io:format("server_inscribirAsistenteConferencia no debio de haber llegado a una lista vacia", []),
	[];
server_inscribirAsistenteConferencia(From, Asistente, Conferencia, L_Asistentes) ->
	[MapAsistente | Rest] = L_Asistentes,
	%io:format("~p == ~p ~n", [MapAsistente, Asistente]),
	case maps:get("clave",MapAsistente) == Asistente of
		true ->
			io:format("~p + ~p = ~p~n", [maps:get("conferencias",MapAsistente), Conferencia,
				[Conferencia | maps:get("conferencias",MapAsistente)]]),
			MapNuevoAsistente = maps:update("conferencias", [Conferencia | maps:get("conferencias",MapAsistente)], MapAsistente),
			[MapNuevoAsistente | Rest];
		false -> 
			[MapAsistente | server_inscribirAsistenteConferencia(From, Asistente, Conferencia, Rest)]
		end. 

%Manda el mensaje de error correspondiente cuando se quiere registrar un asistente a una conferencia 
%llena o el asistente ya no puede
server_cupollenoAsistenteConferencia(From, CupoAsistente, CupoConferencia, EstaInscrito) ->
	%io:format("cupo de conf y de asistente ~p ~p ~n", [CupoAsistente, CupoConferencia]),
	case EstaInscrito of
		false ->
			case CupoAsistente of
				false ->
					case CupoConferencia of
						false ->
							From ! {servidor, asistente_y_conferencia_llenos};
						true ->
							From ! {servidor, asistente_lleno}
						end;
				true ->
					From ! {servidor, conferencia_llena}
				end;
		true ->
			From ! {servidor, asistente_ya_estaba_inscrito}
		end.

%Manda el mensaje de error correspondiente cuando se quiere registrar un asistente a una conferencia
server_inexistenteAsistenteConferencia(From, ExisteAsistente, ExisteConferencia) ->
	%io:format("existentes conf ~p ~p ~n", [ExisteAsistente, ExisteConferencia]),
	case ExisteAsistente of
		false ->
			case ExisteConferencia of
				false ->
					From ! {servidor, asistente_y_conferencia_inexixtentes};
				true ->
					From ! {servidor, asistente_inexixtente}
				end;
		true ->
			From ! {servidor, conferencia_inexixtente}
		end.


% se imprime la lista de conferencias de un asistente
%server_conferenciasDe(_, _, []) ->
%	io:format("server_conferenciasDe no debio de haber llegado a una lista vacia", []),
%	[];
%server_conferenciasDe(From, Asistente, L_Asistentes) ->
%	foreach 
%	 case maps:find(From, 1, L_Asistentes) of
%		error ->
%	 		From ! {tarea6, stop, asistente_no_registrado};
%	 	{value, {_, Name}} ->
%			server_transfer(From, Name, To, Message, User_List)
%	 end.

% Recorre la lista de mapas para ver si existe un asistente repetido. False = no se repite.
server_checaExistenciaAsistente(_, []) ->
	false;
server_checaExistenciaAsistente(Asistente, L_Asistentes) ->
	[MapAsistente | Rest] = L_Asistentes,
	io:format("~p == ~p ~n", [MapAsistente, Asistente]),
	case maps:get("clave",MapAsistente) == Asistente of
		true ->
			true;
		false -> 
			server_checaExistenciaAsistente(Asistente, Rest)
		end. 


% se agrega un nuevo asistente a la lista del server
server_nuevoAsistente(From, Asistente, Nombre, L_Asistentes) ->
	Existe = server_checaExistenciaAsistente(Asistente, L_Asistentes),
	case Existe of
		true ->
			From ! {servidor, asistente_no_registrado}, %reject register
			L_Asistentes;
		false ->
			Map = #{"clave" => Asistente, "nombre" => Nombre, "conferencias" => []},
			From ! {servidor, asistente_registrado},
			link(From),
			io:format("Lista actual: ~p~n", [[Map | L_Asistentes]]),
			[Map | L_Asistentes] %add user to the list
		end.


% se agrega una nueva conferencia
server_nuevaConferencia(From, Conferencia, L_Conferencias) ->
	Existe = lists:keymember(Conferencia, 2, L_Conferencias),
	case Existe of
		true ->
			From ! {servidor, conferencia_no_registrada_ya_existe}, %rechazar registro
			L_Conferencias;
		false ->
			io:format("~p~n", [{From, Conferencia}]),
			From ! {servidor, conferencia_agregada},
			link(From),
			io:format("Conferencias actuales: ~p~n", [[{From, Conferencia} | L_Conferencias]]),
			[{From, Conferencia} | L_Conferencias]
		end.


%% Empieza el servidor
inicia_servidor() ->
	register(servidor, spawn(tarea6, servidor, [])).
% --------------------------------------------------------------- Asistente

% NOTAS IMPORTANTES:
%	Casa asistente solo se puede inscribir a un maximo de 3 conferencias
%	Para inscribirse debe conocer la clave unica de la conferencia
% 	Puede solicitar las claves de las conferencias
%	Para que se pueda inscribir a una conferencia debe estar registrado en el sistema

%registra_asistente(Asistente, Nombre)
%	Asistente -> atomo usado como clave unica
%	Nombre -> String con nombre del asistente

% inciar el proceso de agregar un asistente
registra_asistente(Asistente, Nombre) ->
	case whereis(Asistente) of
		undefined ->
			register(Asistente,
				spawn(tarea6, asistente, [nodo_servidor(), Asistente, Nombre]));
		_ -> error_asistente_ya_registrado_atomo
	end.

asistente(Server_Node, Asistente, Nombre) ->
	{servidor, Server_Node} ! {self(), registra_a, Asistente, Nombre},
	await_result(),
	asistente(Server_Node). % crear el proceso

% proceso del asistente
asistente(Server_Node) ->
	receive
		logoff ->
			io:format("Termiando proceso..~n", []),
			exit(normal)
	end,
asistente(Server_Node).

%elimina_asistente(Asistente)
%	eliminar todas las inscripciones a conferencias de Asistente
elimina_asistente(Asistente) ->
	{servidor, nodo_servidor()} ! {self(), elimina_a, Asistente},
	await_result().


%inscribe_conferencia(Asistente, Conferencia)
% Asistente -> clave unica del asistente
% Conferencia -> clave unica de la Conferencia
inscribe_conferencia(Asistente, Conferencia) ->
	{servidor, nodo_servidor()} ! {self(), Asistente, Conferencia, inscribe_c}, % inscribe conferencia
	await_result().

%desinscribe_conferencia(Asistente, Conferencia)
% Asistente -> clave unica del asistente
% Conferencia -> clave unica de la Conferencia
desinscribe_conferencia(Asistente, Conferencia) ->
	{servidor, nodo_servidor()} ! {self(), Asistente, Conferencia, desinscribe}, % inscribe conferencia
	await_result().
%conferencias_inscritas(Asistente)
%	Despliega claves, titulos, horarios, cupos y asistentes inscritos

conferencias_inscritas(Asistente) ->
	case whereis(Asistente) of
		undefined ->
			no_existe_asistente;
		_ -> 
			{servidor, nodo_servidor()} ! {self(), conferencias_de, Asistente},
			receive
				{conferencias_de, What} -> % Normal response
					io:format("~p~n", [What])
			after 5000 ->
				io:format("No response from server~n", []),
				exit(timeout)
			end
	end.

% --------------------------------------------------------------- Conferencia

% NOTAS IMPORTANTES:
%	Si la conferencia ya no tiene cupo, ya no se pueden inscribir
% 	Usar un mapa y una lista con la clave de asistentes

%registra_conferencia(Conferencia, Titulo, Conferencista, Horario, Cupo)
%	Conferencia -> Atomo nombre de proceso unico
%	Titulo -> String
%	Conferencista -> String
%	Horario -> Entero con la hora en el rango [8,20]
%	Cupo -> Entero positivo

registra_conferencia(Conferencia, Titulo, Conferencista, Horario, Cupo) ->
	case whereis(Conferencia) of
		undefined -> % crear el proceso
			register(Conferencia,
				spawn(tarea6, conferencia, [nodo_servidor(), Conferencia, Titulo, Conferencista, Horario, Cupo]));
		_ -> error_conferencia_ya_registrada_atomo
	end.

% iniciando creacion de conferencia
conferencia(Server_Node, Conferencia, Titulo, Conferencista, Horario, Cupo) ->
	MapConferencia = #{"conferencia" => Conferencia, "titulo" => Titulo, "conferencista" => Conferencista,
		"horario" => Horario, "cupo" => Cupo, "asistentes" => []},
	io:format("Conferencia: ~p~n", [{self(), Conferencia}]),
	{servidor, Server_Node} ! {self(), Conferencia, registra_c}, % informar al server
	await_result(),
	io:format("Conferencia: ~p~n", [MapConferencia]),
	conferencia(MapConferencia).

%elimina_conferencia(Conferencia)
%	Eliminar todas las inscripciones, borrarla de la info de los asistentes
server_eliminaAsistenteDeLista(_, [], Acum) ->
	io:format("Lista actual: ~p~n", [Acum]),
	Acum;
server_eliminaAsistenteDeLista(Asistente, [MapAsistente | Rest], Acum) ->
	io:format("~p == ~p ~n", [MapAsistente, Asistente]),
    	case MapAsistente == Asistente of
        	true ->
      		      	server_eliminaAsistenteDeLista(Asistente, Rest, Acum);
        	false -> 
            		server_eliminaAsistenteDeLista(Asistente, Rest, lists:append(Acum, [MapAsistente]))
    	end. 

% % proceso que realiza una conferencia una vez que esta linkeada y lista
conferencia(MapConferencia) ->
	receive
		{Server, checar_cupo} ->
			io:format("Conferencia: ~p ~p ~n", [length(maps:get("asistentes",MapConferencia)), maps:get("cupo",MapConferencia)]),
			Server ! {checar_cupo, length(maps:get("asistentes",MapConferencia)) < maps:get("cupo",MapConferencia)},
			conferencia(MapConferencia);
		{Server, registrar_asistente, Asistente} ->
			io:format("Conferencia: ~p~n Asistente: ~p~n", [MapConferencia, Asistente]),
			MapNuevoConferencia = maps:update("asistentes", [Asistente | maps:get("asistentes",MapConferencia)], MapConferencia),
			io:format("NUEVA Conferencia: ~p~n", [MapNuevoConferencia]),
			Server ! {registrar_asistente, asistente_inscrito},
			conferencia(MapNuevoConferencia);
		{Server, desinscribir_asistente, Asistente} ->
			io:format("Conferencia: ~p~n Asistente: ~p~n", [MapConferencia, Asistente]),
			MapNuevoConferencia = maps:update("asistentes", server_eliminaAsistenteDeLista(Asistente, maps:get("asistentes",MapConferencia), []), MapConferencia),
			io:format("NUEVA Conferencia: ~p~n", [MapNuevoConferencia]),
			Server ! {desinscribir_asistente, asistente_desinscrito},
			conferencia(MapNuevoConferencia);
		{Server, asistentes_en} ->
			Server ! {asistentes_en, maps:get("asistentes",MapConferencia)},
			conferencia(MapConferencia);
		{Server, imprime_informacion} ->
		      	Server ! {una_conferencia, MapConferencia},
		      	conferencia(MapConferencia);
		logoff ->
			io:format("Cerrando conferencia..~n", []),
			exit(normal)
	end.
	

%elimina_conferencia(Conferencia)
%	Eliminar todas las inscripciones, borrarla de la info de los asistentes
server_eliminaAsistente(_, [], Acum) ->
	io:format("Lista actual: ~p~n", [Acum]),
	Acum;
server_eliminaAsistente(Asistente, [MapAsistente | Rest], Acum) ->
	io:format("~p == ~p ~n", [MapAsistente, Asistente]),
    	case maps:find("clave", MapAsistente) == {ok,Asistente} of
        	true ->
      		      	server_eliminaAsistente(Asistente, Rest, Acum);
        	false -> 
            		server_eliminaAsistente(Asistente, Rest, lists:append(Acum, [MapAsistente]))
    	end. 

%asistentes_inscritos(Conferencia)
%	Muestra las claves y nombres de los asistentes de esta conferencia
asistentes_inscritos(Conferencia) ->
	{servidor, nodo_servidor()} ! {self(), asistentes_en, Conferencia},
		receive
			{asistentes_en, What} -> % Normal response
				io:format("Los asistentes a la conferencia son: ~p~n", [What])
		after 5000 ->
			io:format("No response from server~n", []),
			exit(timeout)
		end.

% --------------------------------------------------------------- Administracion

% NOTAS IMPORTANTES:
%	Solo este conoce la info de los asistentes y conferencias
%	Debe tener en una lista mapas
%	Cada mapa debe contener la clave de asistente, su nombre y su lista de conferencias
% 	Tener una lista con las claves de las conferencias registradas
%	SI ESTE PROCESO TERMINA TODO LO DEMAS TAMBIEN TERMINA
%	SI UN EVENTO TERMINA DEBE QUITAR TODOS LOS REGISTROS

% lista_asistentes()
%	Muestra a todos los asistentes registrados
%%  asistente: [#{clave => CLAVE,
%%                nombre => NOMBRE,
%%                conferencias => [C1, C2, C3, ...]}...]
print_conferencias_de_asistente([]) ->
  io:format("  No hay mas conferencias por mostrar~n", []);
print_conferencias_de_asistente([Conferencia | Resto]) ->
  io:format("   Conferencia ~p~n", [Conferencia]),
  print_conferencias_de_asistente(Resto).

print_asistente_temp([Map | Resto]) ->
  io:format("Informacion de ~p con clave ~p:~n",
            [maps:get("nombre",Map), maps:get("clave",Map)]),
  print_conferencias_de_asistente([maps:get("conferencias", Map)]),
  print_asistente_temp(Resto);
print_asistente_temp([]) ->
  ok.

lista_asistentes() ->
	{servidor, nodo_servidor()} ! {self(), lista_a}, % pide al servidor al info
  receive
    {lista, L_Asistentes} ->
      print_asistente_temp(L_Asistentes)
  end.

% lista_conferencias()
%	Muestra a todas las conferencias registradas
%%  conferencia: [#{conferencia => CONFERENCIA,
%%                  titulo => TITULO,
%%                  conferencista => CONFERENCISTA,
%%                  horario => HORARIO,
%%                  cupo => CUPO,
print_asistentes_de_conferencia([]) ->
  io:format("  No hay mas asistentes por mostrar~n", []);
print_asistentes_de_conferencia([Asistente | Resto]) ->
  io:format("   Asistente: ~p~n", [Asistente]),
  print_asistentes_de_conferencia(Resto).

print_conferencias_temp([]) ->
  ok;
print_conferencias_temp([Map | Resto]) ->
  io:format("Informacion de conferencia ~p con clave ~p impartida por ~p a la hora de ~p con cupo de ~p:~n",
            [maps:get("titulo",Map), maps:get("conferencia",Map),
             maps:get("conferencista",Map), maps:get("horario",Map), maps:get("cupo",Map)]),
  print_asistentes_de_conferencia([maps:get("asistentes", Map)]),
  print_conferencias_temp(Resto).

%funcion llamada desde el servidor para imprimir la info de cada conferencia
server_pide_conferencia([Tupla | Resto], ListaMapa, Requester) ->
  {Pid, _} = Tupla,
  Pid ! {self(), imprime_informacion},
  receive
    {una_conferencia, Mapa} ->
      NuevaLista = ListaMapa++[Mapa]
  after 5000 ->
      io:format("No se consiguio la informacion", []),
      NuevaLista = ListaMapa
  end,
  server_pide_conferencia(Resto, NuevaLista, Requester);
server_pide_conferencia([], ListaMapa, Requester) ->
  Requester ! {lista_hecha, ListaMapa}.

lista_conferencias() ->
	{servidor, nodo_servidor()} ! {self(), lista_conferencias}, % pide al servidor al info
  receive
    {lista_hecha, Conferencias} ->
      print_conferencias_temp(Conferencias)
  end.
% funcion que espera respuesta del servidor
await_result() ->
	receive
		{servidor, stop, Why} -> % Stop the client
			io:format("~p~n", [Why]),
			exit(normal);
		{servidor, What} -> % Normal response
			io:format("~p~n", [What])
	after 5000 ->
		io:format("No response from server~n", []),
		exit(timeout)
	end.
