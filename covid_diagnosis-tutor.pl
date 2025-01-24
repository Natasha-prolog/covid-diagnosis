:- dynamic patient/4.
:- dynamic development/3.

% A predicate that adds a new patient or updates an existing one
add_patient(Name, Age, Sex, Conditions) :-
    (   patient(Name, _, _, _) % check if the patient already exists
    ->  retractall(patient(Name, _, _, _)), % remove the old data
        assertz(patient(Name, Age, Sex, Conditions)) % add the new data
    ;   assertz(patient(Name, Age, Sex, Conditions)) % add the new patient
    ).

% A predicate that adds symptom development for a patient
add_development(Name, Date, Symptoms) :-
    (   development(Name, _, _) % check if the development data already exists
    ->  retractall(development(Name, _, _)), % remove the old data
        assertz(development(Name, Date, Symptoms)) % add the new data
    ;   assertz(development(Name, Date, Symptoms)) % add the new symptoms
    ).

% A predicate to print the patient's data
print_patient(Name) :-
    patient(Name, Age, Sex, Conditions),
    format("Name: ~w~nAge: ~w~nSex: ~w~nConditions: ~w~n", [Name, Age, Sex, Conditions]).

% A predicate to print the patient's symptom development data
print_dev(Name) :-
    development(Name, Date, Symptoms),
    format("Name: ~w~nDate: ~w~nSymptoms: ~w~n", [Name, Date, Symptoms]).

% Define some facts about symptoms
% Common symptoms
symptom(fever, common).
symptom(dry_cough, common).
symptom(tiredness, common).
% Uncommon symptoms
symptom(smell_loss, uncommon).
symptom(taste_loss, uncommon).
symptom(running_nose, uncommon).
symptom(pain, uncommon).
symptom(sore_throat, uncommon).
symptom(diarrhea, uncommon).
symptom(headache, uncommon).
symptom(conjunctivitis, uncommon).
% Severe symptoms
symptom(short_breath, severe).
symptom(diff_breath, severe).
symptom(chest_pain, severe).
symptom(chest_pressure, severe).
symptom(speech_loss, severe).
symptom(movement_loss, severe).

% Pre-existing conditions that put one at higher risk
precondition([hypertension, diabetes, cardiovascular, chronic_respiratory, cancer]).

% Predicate to check if a list is a subset of another
subset([], _).
subset([H|T], List) :-
    member(H, List),
    subset(T, List).

% Define a predicate to return the risk level based on age, sex, and conditions
risk(Name, Factor) :-
    patient(Name, Age, Sex, Conditions),
    risk(Age, Sex, Conditions, Factor).

% Helper predicate to determine risk based on age, sex, and conditions
risk(Age, Sex, Conditions, Factor) :-
    Age > 70,
    precondition(L1),
    subset(Conditions, L1),
    Factor = 3, !. % High risk if older than 70 and has preconditions
risk(Age, Sex, Conditions, Factor) :-
    Sex = male,
    Factor = 2, !. % Medium risk if male
risk(Age, Sex, Conditions, Factor) :-
    Age < 70,
    Sex = female,
    Factor = 1. % Low risk if younger than 70 and female

% Define the risk level for different symptoms
risk_level(common, 2).
risk_level(uncommon, 1).
risk_level(severe, 3).

% Predicate to get the maximum of two risk levels
max(Risk1, Risk2, Risk) :- Risk is max(Risk1, Risk2).

% Rule to calculate the infection risk based on symptoms and patient risk factor
infection_risk(Name, Risk) :-
    development(Name, _, Symptoms),
    risk(Name, Factor),
    infection_risk(Symptoms, Factor, Risk).

% Helper rule to calculate the infection risk based on a list of symptoms and risk factor
infection_risk([], _, 0). % Base case: no symptoms
infection_risk([H|T], Factor, Risk) :-
    symptom(H, Level),
    risk_level(Level, Risk1),
    infection_risk(T, Factor, Risk2),
    max(Risk1, Risk2, Risk3),
    (Factor == 3 -> Risk is Risk3 + 1; Risk is Risk3). % If high risk factor, add 1

% Predicate to check if a patient has severe symptoms
has_severe_symptom([]) :- fail.
has_severe_symptom([H|T]) :-
    symptom(H, severe) ; has_severe_symptom(T).

% Rule to check if a patient needs medical attention (has severe symptoms)
medical_attention(Name) :-
    development(Name, _, Symptoms),
    has_severe_symptom(Symptoms).

% Predicate to check if the patient has either dry cough or running nose
has_dry_cough_or_running_nose(Name) :-
    development(Name, _, Symptoms),
    (member(dry_cough, Symptoms) ; member(running_nose, Symptoms)).

% Rule to check if the patient is highly infectious
highly_infectious(Name) :-
    has_dry_cough_or_running_nose(Name),
    (infection_risk(Name, 2) ; infection_risk(Name, 3)).

% Rule to calculate the end date of the infectious period
infectious_end_date(StartDate, EndDate) :-
    date_time_stamp(StartDate, StartStamp),
    EndStamp is StartStamp + 15 * 86400, % add 15 days
    stamp_date_time(EndStamp, EndDate, local).

% Convert a date string to a date structure
date_string_to_date(DateString, StartDate) :-
    parse_time(DateString, iso_8601, Stamp),
    stamp_date_time(Stamp, StartDate, 'UTC').

% Convert a date structure to a date string
date_to_date_string(EndDate, EndString) :-
    format_time(string(EndString), '%F', EndDate).

% Rule to calculate the infectious period (14-16 days)
infectious_period(Name, Date, EndString) :-
    development(Name, Date, _),
    highly_infectious(Name),
    date_string_to_date(Date, Start),
    infectious_end_date(Start, EndDate),
    date_to_date_string(EndDate, EndString).

% Main user interface predicate
start :-
    write('Welcome to the COVID-19 diagnosis expert system.'), nl,
    write('Please enter the name of the patient: '),
    read(Name),
    write('Please enter the age of the patient: '),
    read(Age),
    write('Please enter the sex of the patient: '),
    read(Sex),
    write('Please enter the date of symptom onset (YYYY-MM-DD): '),
    read(Date),
    write('Please enter the list of symptoms separated by commas: '),
    read(Symptoms),
    write('Please enter the list of pre-existing conditions separated by commas: '),
    read(Conditions),
    add_patient(Name, Age, Sex, Conditions),
    % format("DEBUG Name: ~w~nAge: ~w~nSex: ~w~nConditions: ~w~n", [Name, Age, Sex, Conditions]), fail,
    add_development(Name, Date, Symptoms),
    print_patient(Name),
    print_dev(Name),
    write('Thank you for your input. Here is the diagnosis: '), nl,
    diagnose(Name).

% Diagnosis predicate
diagnose(Name) :-
    infection_risk(Name, Risk),
    write('The risk of infection is '), write(Risk), write('.'), nl,
    (medical_attention(Name) -> write('The patient needs medical attention. Call the nearest health facility immediately!!'), nl; write('The patient should manage symptoms at home.'), nl),
    (highly_infectious(Name) -> write('The patient is highly infectious and should isolate from others.'), nl; write('The patient is not highly infectious, keep distance from others when possible.')),
    infectious_period(Name, Date, EndString),
    write('The infectious period is from '), write(Date), write(' to '), write(EndString), write('.'), nl.

