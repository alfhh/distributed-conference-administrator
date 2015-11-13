% Tarea 6 - Erlang
% Alfredo Hinojosa Huerta A01036053
% Sergio Cordero Barrera A01191167
% Luis Juan Sanchez Padilla A01183634
% Rodolfo Cantu Ortiz A01036042
%
% --------------------------------------------------------------- Meta
-module(asistencia).
-export([inicia_servidor/0, servidor/0]).

%% cambia la funcion acontinuacion para que refleje el nombre del
%% nodo servidor (para ver tu nombre corre en UNIX con el comando
%% 'sudo erl -sname NOMBRE' donde NOMBRE es el nombre que quieres
%% usar. Acontinuacion, el nombre estara antes del numero de linea
%% a ejecutar.
nodo_servidor() ->
  super@debian.

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
  servidor(maps:new(), maps:new()). % llama al servidor con 2 mapas vacios

servidor(Asistentes, Conferencias) ->
  receive
 %TODO agrega las funciones por las que va a escuchar nuestro servidor
  end.

%% Empieza el servidor
inicia_servidor() ->
	register(asistencia, spawn(asistencia, servidor, [])).
% --------------------------------------------------------------- Asistente

% NOTAS IMPORTANTES:
%	Casa asistente solo se puede inscribir a un maximo de 3 conferencias
%	Para inscribirse debe conocer la clave unica de la conferencia
% 	Puede solicitar las claves de las conferencias
%	Para que se pueda inscribir a una conferencia debe estar registrado en el sistema

%registra_asistente(Asistente, Nombre)
%	Asistente -> atomo usado como clave unica
%	Nombre -> String con nombre del asistente

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
