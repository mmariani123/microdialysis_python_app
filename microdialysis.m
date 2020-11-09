function varargout = microdialysis(varargin)
% MICRODIALYSIS MATLAB code for microdialysis.fig
%      MICRODIALYSIS, by itself, creates a new MICRODIALYSIS or raises the existing
%      singleton*.
%
%      H = MICRODIALYSIS returns the handle to a new MICRODIALYSIS or the handle to
%      the existing singleton*.
%
%      MICRODIALYSIS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MICRODIALYSIS.M with the given input arguments.
%
%      MICRODIALYSIS('Property','Value',...) creates a new MICRODIALYSIS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before microdialysis_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to microdialysis_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help microdialysis

% Last Modified by GUIDE v2.5 19-May-2016 15:59:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @microdialysis_OpeningFcn, ...
                   'gui_OutputFcn',  @microdialysis_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before microdialysis is made visible.
function microdialysis_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to microdialysis (see VARARGIN)

% Choose default command line output for microdialysis
handles.output = hObject;

% Update handles structure
pause('on');
handles.samplerRotateTime = 15;
handles.autoCheck = 0;
handles.autoNum = 0;
handles.bytePause = 0.5;
handles.commandPause = 1;
handles.pauseTime = 0.1;
handles.numStopAttempts = 3;
handles.running = true;
handles.flowUnits = 'ul/min';
handles.flowRate = 0;
handles.syringeStroke = 0;
handles.syringeVolume = 0;
handles.syringeVolumeUnits = 'ul';
handles.volume = 0;
handles.presetVolume = 0;
handles.timerStatus = true;
handles.status = true;
handles.timerTime = 0;
handles.presetMax = 0;
handles.commandCell = {};
handles.consoleCell = {};
set(handles.flow_units_toggle,'String','ul/min','FontSize',12);
set(handles.syringe_volume_toggle,'String','ul','FontSize',12);
set(handles.popupmenu1, 'String', ListPorts);
guidata(hObject, handles);

% UIWAIT makes microdialysis wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = microdialysis_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in start_button.
function start_button_Callback(hObject, eventdata, handles)
% hObject    handle to start_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    if(IsSerial(handles))
        handles.autoCheck=1;
        autoNum = handles.autoNum;
        flowRate = handles.flowRate;
        volume = handles.presetVolume*1000;
        totalTime = 1/((flowRate/60)*(1/volume));
        if(handles.autoCheck==1)
            for autoCount = 1:autoNum
                if handles.timerStatus == true
                    t=timer('StartDelay',totalTime);
                    t.TimerFcn = @(x,y)setappdata(gcf,'handles.running',false);
                    t.StartFcn = {@TimerRun,hObject,handles};
                    t.StopFcn = {@Rotate,hObject,handles};
                    start(t);
                    time=0;
                    set(handles.timer_static_text,'String',num2str(time));
                    while(1)
                        h = getappdata(gcf,'HandleStructure');
                        if(getfield(guidata(gcf),'running')~=1)
                            break;
                        else  
                            pause(1);
                            time = time+1;
                            set(handles.timer_static_text,'String',num2str(time));
                            volume = flowRate*(time/60);
                            set(handles.accumulator_static_text,'String',num2str(volume,'%10.3f'));
                        end
                    end
                    delete(t);
                    guidata(hObject,handles);    
                else
                    fprintf(handles.serialObj,'RUN\r\n');
                    handles.running=true;
                    guidata(hObject,handles);
                    time = 0;
                end
                pause(handles.samplerRotateTime);
            end
        else
            error('Error: no Serial Object, make sure to connect.')
        end
    end
catch err
    handles.commandCell{end+1} = err.message;
    set(handles.console_edit_text,'String',handles.commandCell);
end
guidata(hObject,handles);


% --- Executes on button press in stop_button.
function stop_button_Callback(hObject, eventdata, handles)
% hObject    handle to stop_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
StopPump(hObject,handles);


% --- Executes on button press in connect_button.
function connect_button_Callback(hObject, eventdata, handles)
% hObject    handle to connect_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if(isfield(handles,'serialObj'))
     if(isempty(handles.consoleCell))
            handles.consoleCell{1} = 'Serial port already open.';
     else
            handles.consoleCell{end+1,1} = 'Serial port already open.';
     end
    set(handles.console_edit_text,'String',handles.consoleCell);
else
    handles.serialObj = serial('COM4','BaudRate',9600,'DataBits',8,...
        'Parity','none','StopBits',1,'OutputBufferSize',32);
    disp(handles.serialObj.Status);
    fprintf('%i\n', handles.serialObj.Status);
    out = instrfind
    if(strcmpi(handles.serialObj.Status,'open'))
        disp('Port already open!');
    else
        fopen(handles.serialObj);
        if(isempty(handles.consoleCell))
            handles.consoleCell{1} = 'Serial port just opened.';
        else
            handles.consoleCell{end+1,1} = 'Serial port Just Opened!';
        end
        set(handles.console_edit_text,'String',handles.consoleCell,'FontSize',12);
        guidata(hObject,handles);
        guidata(hObject,handles); 
    end
end


% --- Executes on button press in fast_feed_back_button.
function fast_feed_back_button_Callback(hObject, eventdata, handles)
% hObject    handle to fast_feed_back_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fprintf(handles.serialObj,'FFB\r\n');
pause(handles.commandPause);

% --- Executes on button press in fast_feed_forward_button.
function fast_feed_forward_button_Callback(hObject, eventdata, handles)
% hObject    handle to fast_feed_forward_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fprintf(handles.serialObj,'FFF\r\n');
pause(handles.commandPause);


% --- Executes on button press in reset_button.
function reset_button_Callback(hObject, eventdata, handles)
% hObject    handle to reset_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
instrreset;
instrfind
if(isfield(handles,'serialObj'))
    %remove/close the serial object. 
    %fclose(handles.serialObj);
    %delete(handles.serialObj);
    handles = rmfield(handles,'serialObj');
    clear handles.serialObj;
    guidata(hObject,handles);
    set(handles.console_edit_text,'String','');
    set(handles.command_edit_text,'String','');
    set(handles.accumulator_static_text,'String','');
    set(handles.timer_static_text,'String','');
    %reset handles:
    pause('on');
    handles.samplerRotateTime = 15;
    handles.autoCheck=0;
    handles.autoNum = 0;
    handles.bytePause = 0.5;
    handles.commandPause = 1;
    handles.pauseTime = 0.1;
    handles.numStopAttempts = 3;
    handles.running = true;
    handles.flowUnits = 'ul/min';
    handles.flowRate = 0;
    handles.syringeStroke = 0;
    handles.syringeVolume = 0;
    handles.syringeVolumeUnits = 'ul';
    handles.volume = 0;
    handles.presetVolume = 0;
    handles.timerStatus = true;
    handles.status = true;
    handles.timerTime = 0;
    handles.presetMax = 0;
    handles.commandCell = {};
    handles.consoleCell = {};
    set(handles.flow_units_toggle,'String','ul/min','FontSize',20);
    set(handles.popupmenu1, 'String', ListPorts);
    guidata(hObject,handles);
end
set(handles.popupmenu1,'String',ListPorts);
guidata(hObject,handles);



% --- Executes on button press in trigger_microsampler_button.
function trigger_microsampler_button_Callback(hObject, eventdata, handles)
% hObject    handle to trigger_microsampler_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fprintf(handles.serialObj,'RBC\r\n');
pause(handles.commandPause);
fprintf(handles.serialObj,'RBO\r\n');
pause(handles.commandPause);



function console_edit_text_Callback(hObject, eventdata, handles)
% hObject    handle to console_edit_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of console_edit_text as text
%        str2double(get(hObject,'String')) returns contents of console_edit_text as a double


% --- Executes during object creation, after setting all properties.
function console_edit_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to console_edit_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1
contents = cellstr(get(hObject,'String'));
handles.portName = contents{get(hObject,'Value')};
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function command_edit_text_Callback(hObject, eventdata, handles)
% hObject    handle to command_edit_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of command_edit_text as text
%        str2double(get(hObject,'String')) returns contents of command_edit_text as a double


% --- Executes during object creation, after setting all properties.
function command_edit_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to command_edit_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in enter_command_button.
function enter_command_button_Callback(hObject, eventdata, handles)
% hObject    handle to enter_command_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
command = get(handles.command_edit_text,'String');
RunCommand(command,handles);

% --- Executes on button press in clear_console_button.
function clear_console_button_Callback(hObject, eventdata, handles)
% hObject    handle to clear_console_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.console_edit_text,'String','');
handles.consoleCell = {};
guidata(hObject,handles);


% --- Executes on button press in pushbutton12.
function pushbutton12_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in set_syringe_stroke_button.
function set_syringe_stroke_button_Callback(hObject, eventdata, handles)
% hObject    handle to set_syringe_stroke_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
string = get(handles.command_edit_text,'String');
try
    if(isempty(str2double(string))==1)
        error('Error: stroke volume must be numeric.')
    else
        flushinput(handles.serialObj)
        flushoutput(handles.serialObj)
        fprintf(handles.serialObj,strcat('SSM',string,'\r\n'));
        pause(handles.commandPause);
        status = strtrim(fscanf(handles.serialObj));
        if(strcmpi(status,'OK'))
            output = horzcat('Stroke set at: ',string,' mm');
            handles.syringeStroke = str2double(string);
            if(isempty(handles.consoleCell))
                handles.consoleCell{1} = output;
            else
                handles.consoleCell{end+1,1} = output;
            end
            set(handles.console_edit_text,'String',handles.consoleCell);
        elseif(strcmpi(status,'OR'))
            error('Error: syringe stroke value out of range.');
        elseif(strcmpi(status,'COMMAND ERROR'))
            error('Error: command error.');
        end
    end
catch err
      if(isempty(handles.consoleCell))
                handles.consoleCell{1} = err.message;
      else
                handles.consoleCell{end+1,1} = err.message;
      end
      set(handles.console_edit_text,'String',handles.consoleCell);
end
guidata(hObject,handles);
   


% --- Executes on button press in set_syringe_volume_button.
function set_syringe_volume_button_Callback(hObject, eventdata, handles)
% hObject    handle to set_syringe_volume_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
string = get(handles.command_edit_text,'String');
try
    if(isempty(str2double(string))==1)
        error('Error: syringe volume must be numeric.')
    else
        flushinput(handles.serialObj)
        flushoutput(handles.serialObj)
        if(strcmpi(handles.syringeVolumeUnits,'ul'))
            fprintf(handles.serialObj,strcat('SVU',string,'\r\n'));
            pause(handles.commandPause);
        elseif(strcmpi(handles.syringeVolumeUnits,'ml'))
            fprintf(handles.serialObj,strcat('SVM',string,'\r\n'));
            pause(handles.commandPause);
        end
        status = strtrim(fscanf(handles.serialObj));
        if(strcmpi(status,'OK'))
            if(strcmpi(handles.syringeVolumeUnits,'ul'))
                output = horzcat('Syringe volume set at: ',string,' uL');
            elseif(strcmpi(handles.syringeVolumeUnits,'ml'))
                output = horzcat('Syringe volume set at: ',string,' mL');
            end
            handles.syringeVolume = str2double(string);
            if(isempty(handles.consoleCell))
                handles.consoleCell{1} = output;
            else
                handles.consoleCell{end+1,1} = output;
            end
            set(handles.console_edit_text,'String',handles.consoleCell);
        elseif(strcmpi(status,'OR'))
            error('Error: syringe volume value out of range.');
        elseif(strcmpi(status,'COMMAND ERROR'))
            error('Error: command error.');
        end
    end
catch err
      if(isempty(handles.consoleCell))
                handles.consoleCell{1} = err.message;
      else
                handles.consoleCell{end+1,1} = err.message;
      end
      set(handles.console_edit_text,'String',handles.consoleCell);
end
guidata(hObject,handles);

% --- Executes on button press in set_preset_volume_button.
function set_preset_volume_button_Callback(hObject, eventdata, handles)
% hObject    handle to set_preset_volume_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = get(handles.command_edit_text,'String');
numValue = str2double(value);
try
    if(isnan(numValue)==1)
        error('Error: preset volume must be a number.');
    else
        flushinput(handles.serialObj);
        flushoutput(handles.serialObj);
        fprintf(handles.serialObj,horzcat('PRV',value,'\r\n'));
        scan = fscanf(handles.serialObj);
            if(strcmpi(strtrim(scan),'OR'))
                error('Error: specified preset volume is out of range.');
            elseif(strcmpi(strtrim(scan),'COMMAND ERROR'))
                error('Error: command error.');
            elseif(strcmpi(strtrim(scan),'OK'))
                if(isempty(handles.consoleCell))
                    handles.consoleCell{1} = horzcat('Preset volume set at ',value,'.');
                else
                    handles.consoleCell{end+1,1} = horzcat('Preset volume set at ',value,'.');
                end
            set(handles.console_edit_text,'String',handles.consoleCell);
            handles.presetVolume = numValue;
            end
    end
catch err
     if(isempty(handles.consoleCell))
            handles.consoleCell{1} = err.message;
     else
            handles.consoleCell{end+1,1} = err.message;
     end
     set(handles.console_edit_text,'String',handles.consoleCell);
end
guidata(hObject,handles);


% --- Executes on button press in set_flow_rate_button.
function set_flow_rate_button_Callback(hObject, eventdata, handles)
% hObject    handle to set_flow_rate_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
string = get(handles.command_edit_text,'String');
try
    if(isempty(string))
        error('Error: must specify a flowrate value (numeric).');
    elseif(isnan(str2double(string)))
        error('Error: flowrate value nust be a number.');
    end
    flushoutput(handles.serialObj);
    flushinput(handles.serialObj)
    if strcmpi(handles.flowUnits,'ul/min')==1
        output = horzcat(string,' uL/min.');
        fprintf(handles.serialObj,strcat('ULM',string,'\r\n'));
        pause(handles.commandPause);
    elseif strcmpi(handles.flowUnits,'ml/hr')==1
        output = horzcat(string,' ml/hr.');
        fprintf(handles.serialObj,strcat('MLH',string,'\r\n'));
        pause(handles.commandPause);
    else
        error('Error: improper flow rate units, try setting flow rate manually.')
    end
    response = strtrim(fscanf(handles.serialObj));
    if(strcmpi(response,'OR'))
        error('Error: flowrate units out of range.');
    elseif(strcmpi(response,'COMMAND ERROR'));
        error('Error: command error');
    elseif(strcmpi(response,'OK'))
        handles.flowRate = str2double(string);
         if(isempty(handles.consoleCell))
            handles.consoleCell{1} = horzcat('Flowrate set at: ',output);
        else
            handles.consoleCell{end+1,1} = horzcat('Flowrate set at: ',output);
        end
        set(handles.console_edit_text,'String',handles.consoleCell);
    end
catch err
     if(isempty(handles.consoleCell))
            handles.consoleCell{1} = err.message;
     else
            handles.consoleCell{end+1,1} = err.message;
     end
     set(handles.console_edit_text,'String',handles.consoleCell);
end
guidata(hObject,handles);


function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double


% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit4_Callback(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit4 as text
%        str2double(get(hObject,'String')) returns contents of edit4 as a double


% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function timer_static_text_Callback(hObject, eventdata, handles)
% hObject    handle to timer_static_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of timer_static_text as text
%        str2double(get(hObject,'String')) returns contents of timer_static_text as a double


% --- Executes during object creation, after setting all properties.
function timer_static_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timer_static_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in clear_accumulator_button.
function clear_accumulator_button_Callback(hObject, eventdata, handles)
% hObject    handle to clear_accumulator_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.accumulator_static_text,'String','');
flushoutput(handles.serialObj);
flushinput(handles.serialObj);
fprintf(handles.serialObj,'CLV\r\n');
pause(handles.commandPause);
scan = fscanf(handles.serialObj);
try
    if(strcmpi(strtrim(scan),'OK'))
        if(isempty(handles.consoleCell))
            handles.consoleCell{1} = 'Volume accumulator cleared.';
        else
            handles.consoleCell{end+1,1} = 'Volume accumulator cleared.';
        end
        set(handles.console_edit_text,'String',handles.consoleCell);
    else
        error('Error: error clearing the volume accumulator.');
        handles.volume = 0;
    end
catch err
    set(handles.console_edit_text,'String',err.message);
end
guidata(hObject,handles);


% --- Executes on button press in clear_timer_button.
function clear_timer_button_Callback(hObject, eventdata, handles)
% hObject    handle to clear_timer_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.timer_static_text,'String','');


% --- Executes on button press in flow_units_toggle.
function flow_units_toggle_Callback(hObject, eventdata, handles)
% hObject    handle to flow_units_toggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of flow_units_toggle
value = get(hObject,'Value');
if value==0
    handles.flowUnits = 'ul/min';
    set(handles.flow_units_toggle,'String','ul/min','FontSize',12);
else
    handles.flowUnits = 'ml/hr';
    set(handles.flow_units_toggle,'String','ml/hr','FontSize',12);
end
guidata(hObject,handles);
    

% --- Executes on button press in set_timer_button.
function set_timer_button_Callback(hObject, eventdata, handles)
% hObject    handle to set_timer_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
timerString = get(handles.command_edit_text,'String');
try
    if(isnan(str2double(timerString)))
        error('Error: Timer value must be a number.');
    else
        handles.timerMax = str2double(timerString);
        set(handles.timer_static_text,'String',handles.timerTime,'FontSize',40);
        guidata(hObject,handles);
    end
catch err
    set(handles.console_edit_text,'String',err.message);
end


%------------ADDITIONAL FUNCTIONALITY----------------
function ports = ListPorts()
instrOut = instrfind;
if isempty(instrOut)
    ports = {'No ports available'};
else
    for i=1:length(instrOut)
        ports{i} = getfield(instrOut(i),'port');
    end
end

function RunCommand(command,handles)
if strcmpi(command,'stp')
    fprintf(handles.serialObj,'S');
    pause(handles.bytePause);
    fprintf(handles.serialObj,'T');
    pause(handles.bytePause);
    fprintf(handles.serialObj,'P');
    pause(handles.bytePause);
    fprintf(handles.serialObj,'\r');
    pause(handles.bytePause);
    fprintf(handles.serialObj,'\n');
    pause(handles.commandPause);
else
    fprintf(handles.serialObj,command);
    pause(handles.commandPause);
end

function output = IsSerial(handles)
    if(isfield(handles,'serialObj'))
        output = 1;
    else
        output = 0;
    end
    
    
function TimerRun(obj,event,hObject,handles)
    fprintf(handles.serialObj,'RUN\r\n');
    %{
    set(handles.timer_static_text,'String',num2str(0))
    for timeCount = 1:handles.timerMax
        pause(1);
        set(handles.timer_static_text,'String',num2str(timerCount));
    end
    %}

function Rotate(obj,event,hObject,handles)
    %StopPump(hObject,handles);
    handles.running = false;
    handles.status = false;
    pause(handles.commandPause);
    fprintf(handles.serialObj,'RBC\r\n');
    pause(handles.commandPause);
    fprintf(handles.serialObj,'RBO\r\n');
    pause(handles.commandPause);
    guidata(hObject,handles);
    
function StopPump(hObject,handles)
for stopCount = 1: handles.numStopAttempts
        flushinput(handles.serialObj);
        flushoutput(handles.serialObj);
        pauseTime = handles.pauseTime;
        fprintf(handles.serialObj,'%s','S','async');
        pause(pauseTime);
        fprintf(handles.serialObj,'%s','T','async');
        pause(pauseTime);
        fprintf(handles.serialObj,'%s','P','async');
        pause(pauseTime);
        fprintf(handles.serialObj,'%s','\r','async');
        pause(pauseTime);
        fprintf(handles.serialObj,'%s','\n','async');
        pause(pauseTime)
end
        handles.running = false;
        handles.status = false;
        guidata(hObject,handles);
        
    
function AccumVol(handles)
    


% --- Executes during object deletion, before destroying properties.
function set_timer_button_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to set_timer_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in automation_checkbox.
function automation_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to automation_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of automation_checkbox


% --- Executes on button press in automation_button.
function automation_button_Callback(hObject, eventdata, handles)
% hObject    handle to automation_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = get(handles.command_edit_text,'String');
try
    if(isnan(str2double(value)))
        error('Error: Automatic iterations value must be a number.');
    else
        handles.autoNum = str2double(value);
        if(isempty(handles.consoleCell))
                handles.consoleCell{1} = horzcat('Automation iterations set at: ',num2str(handles.autoNum));
        else
                handles.consoleCell{end+1,1} = horzcat('Automation iterations set at: ',num2str(handles.autoNum));
        end
        set(handles.console_edit_text,'String',handles.consoleCell,'FontSize',12);
    end
catch err
      if(isempty(handles.consoleCell))
                handles.consoleCell{1} = err.message;
      else
                handles.consoleCell{end+1,1} = err.message;
      end
      set(handles.console_edit_text,'String',handles.consoleCell);
end
guidata(hObject,handles);


% --- Executes on button press in syringe_volume_toggle.
function syringe_volume_toggle_Callback(hObject, eventdata, handles)
% hObject    handle to syringe_volume_toggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of syringe_volume_toggle
value = get(hObject,'Value');
if value==0
    handles.syringeVolumeUnits = 'ul';
    set(handles.syringe_volume_toggle,'String','ul','FontSize',12);
else
    handles.syringeVolumeUnits = 'ml';
    set(handles.syringe_volume_toggle,'String','ml','FontSize',12);
end
guidata(hObject,handles);


% --- Executes on button press in save_button.
function save_button_Callback(hObject, eventdata, handles)
% hObject    handle to save_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
