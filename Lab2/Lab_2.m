%define some constants
offset = 2;
radius_of_rotor = 1.1/100; % radius of rotor = 1.1(cm) = 1.1/100(m)
weight_of_rotor = 0.017; % weight of rotor = 17g = 0.017kg
gear_ratio = 48; %gear ratio of EV3 motor = 48
L = 0.0047; % do tu cam cua cuon day
type_of_export_graph = '.png';
simulation_model_1_coordinate_stop_time = "3";
simulation_model_1_current_stop_time = "0.5";
% read file
results = readmatrix("current_measure.txt");

% get negative pwm, voltage, current
PWM_N = results(1:10,1);
voltages_N = results(1+offset:10,2);
currents_N = results(1+offset:10,3);
% get positve pwm, voltage, current
PWM_P = results(11:end,1);
voltages_P = results(11:end-offset,2);
currents_P = results(11:end-offset,3);
% Get voltages 
voltages = results(1:end,2);
PWM = results(1:end, 1);

function_to_cal_voltage = @(resistance, current) (current*resistance);

% create predict value
predict_resistance = 50;

% Calculate resistance by using approximation
resistance_P = lsqcurvefit(function_to_cal_voltage, predict_resistance, currents_P, voltages_P);
resistance_N = lsqcurvefit(function_to_cal_voltage, predict_resistance, currents_N, voltages_N);

% Draw graph of U(I) using resistance_N

%     figure("Name", "Negative");
%     hold on
%     plot(currents_N, voltages_N, 'red')
%     plot(currents_N, currents_N*resistance_N, 'k')
%     text(currents_N(end), voltages_N(end), num2str(resistance_N));
%     hold off
% Draw graph of U(I) using resistance_P

%     figure("Name", "Positive");
%     hold on
%     plot(currents_P, voltages_P, 'red')
%     plot(currents_P, currents_P*resistance_P, 'k')
%     text(currents_P(end), voltages_P(end), num2str(resistance_P));
%     hold off

% 1.9 Calculate final resistance value
    resistance = (resistance_P+resistance_N)/2;
    R = resistance;

% 2.1 Calculate moment of inertia and moment of inertia after gearbox
    moment_of_inertia = weight_of_rotor*radius_of_rotor*radius_of_rotor/2
    moment_of_inertia_after_gear_box = moment_of_inertia*gear_ratio*gear_ratio
    J = moment_of_inertia_after_gear_box;
% 2.5 Create 2x 2d array of Wnls which depend on PWM
    funSpeed = @(x,time) x(1)*(1-exp(-time/x(2)));
    funAngle = @(x,time) x(1)*(time-x(2)*(1-exp(-time/x(2))));
    
    array_Wnls_speed=[];
    array_Wnls_cordinate=[];
    array_of_PWM = -100:10:100; %chinh lai sau khi res
    for i = -100:10:100 % chinh lai sau khi res
        results = readmatrix("clear_data_"+num2str(i)+".txt");
        time = results(:,1);
        angles = results(:,2)*pi/180;
        speeds = results(:, 3)*pi/180;
        
        %create predict value
        predict_Wnls = 50;
        predict_Tm = 50;
        
        % get Wnls and Tm using speed data 
        fit_result_speed = lsqcurvefit(funSpeed, ...
                                     [predict_Wnls, predict_Tm], ...
                                     time, ...
                                     speeds);
        array_Wnls_speed = [array_Wnls_speed fit_result_speed(1)];
        % Get Wnls and Tm using angle data
        fit_result_cordinate = lsqcurvefit(funAngle, ...
                                         [predict_Wnls, predict_Tm], ...
                                         time, ...
                                         angles);
        array_Wnls_cordinate = [array_Wnls_cordinate fit_result_cordinate(1)];
    end
    
    array_PWM_Wnls_speed = [array_of_PWM' array_Wnls_speed']
    array_PWM_Wnls_cordinate = [array_of_PWM' array_Wnls_cordinate']

% 2.6 Calculate Ke
    function_to_cal_voltage = @(Ke, Wnls) Ke*Wnls;
    predict_Ke = 1;
    Ke = lsqcurvefit(function_to_cal_voltage, predict_Ke, array_Wnls_speed, voltages')
%     figure("Name", "U(w)");
%     hold on
%     plot(array_Wnls_speed, voltages, '.r')
%     plot(array_Wnls_speed, Ke*array_Wnls_speed, 'g');
%     text(array_Wnls_speed(end)/2, voltages(end)/2, "Ke= "+ num2str(Ke));
%     hold off;
% 2.7 Let Km = Ke
    Km = Ke;

% Run simulation and collect output of current strength
    for i = 1:1:length(voltages)
        U = voltages(i);
        if (U==0) % Bypass the value U = 0
            continue; 
        end 
        set_param("model_lab_2", "StartTime", "0", "StopTime", simulation_model_1_current_stop_time);
        model_1 = sim("model_lab_2.slx");
        figure("Name","Model 1: Voltage = "+num2str(U), "WindowState", "maximized");
        plot(model_1.current.Time, model_1.current.Data, 'blue');
        xlabel("Time, [sec]");
        ylabel("I, [Ampe]");
        grid on;
        grid minor;
        title_of_graph = "I(t) at voltage = " + num2str(U) + "V";
        title(title_of_graph);
        % Set legend for model
        legend("Model");
        path_to_file = "Graphs/Simulation/Currents/U=" + num2str(U) + type_of_export_graph;
        saveas(gcf, path_to_file);
    end

% Run simulation and collect output of coordinate
    for i = 1:1:length(voltages)
        U = voltages(i);
        if (U==0) % Bypass the value U = 0
            continue; 
        end 
        figure("Name","Model 1: Voltage = "+num2str(U), "WindowState", "maximized");
        xlabel("Time, [sec]");
        ylabel("θ, [rad]");
        grid on;
        grid minor;
        hold on;
        title_of_graph = " θ(t) at voltage = " + num2str(U) + "V";
        title(title_of_graph);
        set_param("model_lab_2", "StartTime", "0", "StopTime", simulation_model_1_coordinate_stop_time);
        model_1 = sim("model_lab_2.slx"); %run simulation
        % Graph of simulation's data
        plot(model_1.coordinate.Time, model_1.coordinate.Data, "red");

        % Graph of real coordinate
        real_life_results = readmatrix("clear_data_"+num2str(PWM(i))+".txt");
        real_life_times = real_life_results(:,1);
        real_life_coordinates = real_life_results(:,2)*pi/180;
        plot(real_life_times, real_life_coordinates, "blue");
        hold off;
        % Set legend for experiments and model
        legend("Model", "Experiment");
        % To save graph as png
        path_to_file = "Graphs/Simulation/Coordinate/U=" + num2str(U) + type_of_export_graph;
        saveas(gcf, path_to_file);
    end





% Cal resistance by using formula
% R = 0;
% sumUI = 0;
% sumII = 0;
% for i = 1:length(voltages_N)
%     sumUI = sumUI + voltages_N(i)*currents_N(i);
%     sumII = sumII + currents_N(i)*currents_N(i);
% end
% for i = 1:length(voltages_P)
%     sumUI = sumUI + voltages_P(i)*currents_P(i);
%     sumII = sumII + currents_P(i)*currents_P(i);
% end
% resistance_cal_by_formula = sumUI / sumII