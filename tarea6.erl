% Tarea 6 - Erlang
% Alfredo Hinojosa Huerta A01036053
% Sergio Cordero Barrera A01191167
% Luis Juan Sanchez Padilla A01183634
% Rodolfo Cantu Ortiz A01036042
%
% --------------------------------------------------------------- Meta
-module(tarea6).
-export([inicia_servidor/0, servidor/0, registra_conferencia/5, conferencia/6, 
	registra_asistente/2, asistente/3]).

%% cambia la funcion acontinuacion para que refleje el nombre del
%% nodo servidor (para ver tu nombre corre en UNIX con el comando
%% 'sudo erl -sname NOMBRE' donde NOMBRE es el nombre que quieres
%% usar. Acontinuacion, el nombre estara antes del numero de linea
%% a ejecutar.
nodo_servidor() ->
  servidor@G55.

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

 	{From, registra_c, Conferencia, Titulo, Conferencista, Horario, Cupo} -> % agregar una nueva conferencia
 		Nueva_Conferencias = server_nuevaConferencia(From, Conferencia, Titulo, Conferencista, Horario, Cupo, L_Conferencias),
 		servidor(L_Asistentes, Nueva_Conferencias);

 	{From, registra_a, Asistente, Nombre} -> % agregar un nuevo asistente
 		Nueva_Asistentes = server_nuevoAsistente(From, Asistente, Nombre, L_Asistentes),
 		servidor(Nueva_Asistentes, L_Conferencias)

  end.

server_nuevoAsistente(From, Asistente, Nombre, L_Asistentes) ->
	% checar si el usuario ya existe
	case lists:keymember(Nombre, 2, L_Asistentes) of
		true ->
			From ! {messenger, stop, error_asistente_ya_registrado}, % negar registro
			L_Asistentes;
		false ->
			From ! {messenger, asistente_registrado},
			link(From),
			[{Asistente, Nombre} | L_Asistentes] %add user to the list
	end.

% se agrega una nueva conferencia TODO checar que no sean repetidos
server_nuevaConferencia(From, Conferencia, Titulo, Conferencista, Horario, Cupo, L_Conferencias) ->
	Map = #{"conferencia" => Conferencia, "titulo" => Titulo, "conferencista" => Conferencista,
			"horario" => Horario, "cupo" => Cupo},
	link(From),
	[Map | L_Conferencias],
	From ! {tarea6, conferencia_agregada}.

% solo para hacer pruebas TODO borrar esto
test(From, Titulo) ->
	From ! {tarea6, works}.

%% Empieza el servidor
inicia_servidor() ->
	register(tarea6, spawn(tarea6, servidor, [])).
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
	{tarea6, Server_Node} ! {self(), registra_a, Asistente, Nombre},
	await_result().

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
	{tarea6, Server_Node} ! {self(), registra_c, 
		Conferencia, Titulo, Conferencista, Horario, Cupo}, % informar al server
	await_result().	
% 	conferencia(Server_Node, []).

% % proceso que realiza una conferencia una vez que esta linkeada y lista
% conferencia(Server_Node, Lista_De_Asistentes) ->
% 	receive
% 		% TODO THIS
% 	end,
% 	conferencia(Server_Node, Lista_De_Asistentes).
	

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

% lista_conferencias()
%	Muestra a todas las conferencias registradas

% funcion que espera respuesta del servidor
await_result() ->
	receive
		{tarea6, stop, Why} -> % Stop the client
			io:format("~p~n", [Why]),
			exit(normal);
		{tarea6, What} -> % Normal response
			io:format("~p~n", [What])
	after 5000 ->
		io:format("No response from server~n", []),
		exit(timeout)
	end.
