% Tarea 6 - Erlang
% Alfredo Hinojosa Huerta A01036053
% Sergio Cordero Barrera A01191167
% Luis Juan Sanchez Padilla A01183634
% Rodolfo Cantu Ortiz A01036042
%
% --------------------------------------------------------------- Meta
-module(tarea6).
-export([inicia_servidor/0, servidor/0, registra_conferencia/5, conferencia/6, conferencias_inscritas/1,
	registra_asistente/2, asistente/3, lista_asistentes/0, lista_conferencias/0]).

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

 	{From, lista_c} -> % lista todas las conferencias con los asistentes inscritos
	    From ! {lista, L_Conferencias},
	 		servidor(L_Asistentes, L_Conferencias);

 	{From, lista_a} -> % lista todos los asistentes con las conferencias a las que estan inscritos
	    From ! {lista, L_Asistentes},
	 		servidor(L_Asistentes, L_Conferencias)

 	% {From, conferencias_de, Asistente} -> % imprimir las conferencias de Asistente
 	% 	Resultado = server_conferenciasDe(From, Asistente, L_Asistentes),
 	% 	io:format("las conferencias son: ~p~n", [Resultado])

  end.


% se imprime la lista de conferencias de un asistente
%server_conferenciasDe(From, Asistente, L_Asistentes) ->
	%foreach 
	% case maps:find(From, 1, L_Asistentes) of
	% 	error ->
	% 		From ! {tarea6, stop, asistente_no_registrado};
	% 	{value, {_, Name}} ->
	% 		server_transfer(From, Name, To, Message, User_List)
	% end.

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


% Recorre la lista de mapas para ver si existe una conferencia repetida. False = no se repite.
server_checaExistenciaConferencia(_, []) ->
	false;
server_checaExistenciaConferencia(Conferencia, L_Conferencias) ->
	[MapConferencia | Rest] = L_Conferencias,
	io:format("~p == ~p ~n", [MapConferencia, Conferencia]),
	case maps:get("conferencia",MapConferencia) == Conferencia of
		true ->
			true;
		false -> 
			server_checaExistenciaConferencia(Conferencia, Rest)
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

%inscribe_conferencia(Asistente, Conferencia)
% Asistente -> clave unica del asistente
% Conferencia -> clave unica de la Conferencia

%desinscribe_conferencia(Asistente, Conferencia)
% Asistente -> clave unica del asistente
% Conferencia -> clave unica de la Conferencia

%conferencias_inscritas(Asistente)
%	Despliega claves, titulos, horarios, cupos y asistentes inscritos

conferencias_inscritas(Asistente) ->
	case whereis(Asistente) of
		undefined ->
			no_existe_asistente;
		_ -> 
			{servidor, nodo_servidor()} ! {conferencias_de, Asistente}
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

% % proceso que realiza una conferencia una vez que esta linkeada y lista
conferencia(MapConferencia) ->
	receive
		{registrar_asistente, Asistente} ->
			io:format("Conferencia: ~p~n Asistente: ~p~n", [MapConferencia, Asistente]);
		logoff ->
			io:format("Cerrando conferencia..~n", []),
			exit(normal)
	end,
	conferencia(MapConferencia).
	

%elimina_conferencia(Conferencia)
%	Eliminar todas las inscripciones, borrarla de la info de los asistentes

%asistentes_inscritos(Conferencia)
%	Muestra las claves y nombres de los asistentes de esta conferencia

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
%%                  asistentes => [A1, A2, A3, ...]}...]
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
  print_asistente_temp(Resto).

lista_conferencias() ->
	{servidor, nodo_servidor()} ! {self(), lista_c}, % pide al servidor al info
  receive
    {lista, L_Conferencias} ->
      print_conferencias_temp(L_Conferencias)
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
