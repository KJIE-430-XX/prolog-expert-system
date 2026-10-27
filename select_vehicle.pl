% declare yes/1 and no/1 as dynamic predicates, allowing their facts to be added or removed while the program is running.
:- dynamic yes/1, no/1.

% =========================================================================
% FACTS: Question Text
% =========================================================================
prompt_text(passengers_six_or_more,      'Do you regularly need to seat more than 5 passengers?').
prompt_text(offroad_capable,      'Do you frequently drive off-road or on rough, unpaved terrain?').
prompt_text(heavy_hauler,      'Do you need high cargo capacity or heavy towing capability?').
prompt_text(higher_seating,  'Do you prefer a higher driving position for better visibility of the road?').
prompt_text(versatile_cargo, 'Do you often carry groceries, luggage, sports equipment or other large items?').
prompt_text(pure_ev,      'Do you prefer a pure electric vehicle (EV) over a hybrid or standard petrol/diesel vehicle?').
prompt_text(city_commuter,      'Do you prioritize easy city parking and maneuverability over interior space?').
prompt_text(performance_oriented,      'Do you prioritize sports performance and aggressive handling over everyday practicality?').


% =========================================================================
% TOP LAYER: Outcomes (Maps Middle-Layer Abstractions -> Final Vehicle)
% This also defines the order in which Prolog asks questions
% =========================================================================

% Rule 1
recommend('Pure Electric Commuter (EV)') :-
    pref(pure_ev),
    it_is(city_commuter).

% Rule 2
recommend('Compact Hatchback') :-
    it_is(city_commuter),
    \+ it_is(large_family), % improvement: not a large family (or unknown)
    \+ pref(pure_ev),
    \+ it_is(heavy_hauler),
    \+ it_is(offroad_capable),
    \+ it_is(performance_oriented).

% Rule 3
recommend('SUV') :-
    it_is(daily_passenger),
    it_is(higher_seating),
    \+ it_is(heavy_hauler),
    \+ it_is(performance_oriented).

% Rule 4
recommend('Wagon / Estate') :-
    it_is(daily_passenger),
    it_is(extra_cargo_need),
    \+ it_is(higher_seating),
    \+ it_is(offroad_capable),
    \+ it_is(heavy_hauler),
    \+ it_is(city_commuter),
    \+ it_is(performance_oriented).

% Rule 5
recommend('MPV / Minivan') :-
    it_is(large_family).

% Rule 6
recommend('Pickup Truck') :-
    it_is(heavy_hauler),
    it_is(offroad_capable).

% Rule 7
recommend('Coupe / Sports Car') :-
    it_is(performance_oriented),
    \+ it_is(large_family).

% Rule 8
recommend('Sedan') :-
    it_is(daily_passenger),
    \+ it_is(city_commuter),
    \+ it_is(offroad_capable),
    \+ it_is(heavy_hauler),
    \+ it_is(versatile_cargo),
    \+ it_is(performance_oriented).

% =========================================================================
% MIDDLE LAYER 1: Functional Domain Concepts (it_is/1)
% Abstracts direct user answers into higher-level logical states
% =========================================================================

% Rule 9
it_is(city_commuter) :-
    verify(city_commuter).

% Rule 10
it_is(large_family) :-
    verify(passengers_six_or_more).

% Rule 11
it_is(offroad_capable) :-
    verify(offroad_capable).

% Rule 12
it_is(heavy_hauler) :-
    verify(heavy_hauler).

% Rule 13
it_is(extra_cargo_need) :-
    it_is(versatile_cargo).

% Rule 14
it_is(performance_oriented) :-
    verify(performance_oriented).

% Rule 15
it_is(daily_passenger) :- 
    \+ it_is(large_family).

% Rule 16
it_is(higher_seating) :-
    verify(higher_seating).

% Rule 17
it_is(versatile_cargo) :-
    verify(versatile_cargo).

% =========================================================================
% MIDDLE LAYER 2: Preferences
% =========================================================================

% Rule 18
pref(pure_ev) :- verify(pure_ev).

% -------------------------------------------------------------------------
% verify/1: Checks if a question has already been answered, or asks the user.
% -------------------------------------------------------------------------

% Case 1: If the answer is already stored as yes, succeed immediately.
verify(Question) :-
    yes(Question), !.

% Case 2: If the answer is already stored as no, fail immediately.
verify(Question) :-
    no(Question), !, fail.

% Case 3: If the answer is not stored yet, ask the user and save the result.
verify(Question) :-
    ask(Question, Response),
    (   Response == yes
    ->  assertz(yes(Question))        % Store positive answer
    ;   assertz(no(Question)), fail   % Store negative answer and fail
    ).


% -------------------------------------------------------------------------
% ask/2: Displays the prompt, reads user input safely, and validates it.
% -------------------------------------------------------------------------
ask(Question, Response) :-
    prompt_text(Question, Text),        % Retrieve the question text
    format('~n~w (y/n)? ', [Text]),     % Display question to the user
    flush_output,
    read_line_to_string(user_input, InputStr), % Read line safely without needing a dot (.)
    string_lower(InputStr, LowerStr),
    (   (LowerStr == "y" ; LowerStr == "yes") 
    ->  Response = yes
    ;   (LowerStr == "n" ; LowerStr == "no") 
    ->  Response = no
    ;   format('Invalid input. Please answer with "y" or "n".~n'), % Handle invalid input
        ask(Question, Response)         % Repeat prompt until valid
    ).

% =========================================================================
% ENTRY POINT
% =========================================================================
start :-
    retractall(yes(_)),
    retractall(no(_)),
    (   recommend(Vehicle)
    ->  format('~n--------------------------------------------------~n'),
        format('Recommended vehicle type: ~w~n', [Vehicle]),
        format('--------------------------------------------------~n~n'),
        explain(Vehicle)
    ;   format('~n--------------------------------------------------~n'),
        format('No single standard vehicle type fits all criteria.~n'),
        format('Consider compromising on off-road capability or fuel type.~n'),
        format('--------------------------------------------------~n')
    ).

% =========================================================================
% EXPLANATION FACTS
% =========================================================================
 
% description(Vehicle, Text): what the vehicle type is
description('Compact Hatchback',            'Small, easy to park, suitable for city driving.').
description('Sedan',                        'Comfortable 4-5 seat car for normal daily driving.').
description('SUV',                          'Higher seating position with flexible passenger and cargo space.').
description('MPV / Minivan',                '6-8 seats, designed mainly for families.').
description('Pickup Truck',                 'Built for cargo, towing and rugged or off-road use.').
description('Coupe / Sports Car',           'Low seating with sporty performance and handling.').
description('Wagon / Estate',               '5 seats with extra cargo space.').
description('Pure Electric Commuter (EV)',  'Zero-emission electric drive, quiet and low running cost for city commuting.').
 
% tradeoff(Vehicle, Text): the honest downside the user should know about
tradeoff('Compact Hatchback',            'Limited rear space and cargo capacity for large loads.').
tradeoff('Sedan',                        'Not suited to rough terrain or bulky/heavy cargo.').
tradeoff('SUV',                          'Larger and harder to park in tight city spaces; usually higher fuel use.').
tradeoff('MPV / Minivan',                'Large body makes parking and sporty handling difficult.').
tradeoff('Pickup Truck',                 'Ride comfort, parking ease and fuel efficiency are weaker than a normal car.').
tradeoff('Coupe / Sports Car',           'Limited rear seating, cargo space and everyday practicality.').
tradeoff('Wagon / Estate',               'Not designed for rough terrain, and larger than a hatchback to park.').
tradeoff('Pure Electric Commuter (EV)',  'Depends on charging access and has limited range for long trips.').
 
% rationale(Vehicle, [Question-Answer, ...]): the answers that support the rule
rationale('Compact Hatchback',           [city_commuter-yes, passengers_six_or_more-no, pure_ev-no, heavy_hauler-no, offroad_capable-no, performance_oriented-no]).
rationale('Sedan',                       [passengers_six_or_more-no, city_commuter-no, offroad_capable-no, heavy_hauler-no, performance_oriented-no]).
rationale('SUV',                         [passengers_six_or_more-no, higher_seating-yes, versatile_cargo-yes, heavy_hauler-no]).
rationale('MPV / Minivan',               [passengers_six_or_more-yes]).
rationale('Pickup Truck',                [heavy_hauler-yes, offroad_capable-yes]).
rationale('Coupe / Sports Car',          [performance_oriented-yes, passengers_six_or_more-no]).
rationale('Wagon / Estate',              [passengers_six_or_more-no, heavy_hauler-yes, offroad_capable-no]).
rationale('Pure Electric Commuter (EV)', [city_commuter-yes, pure_ev-yes]).
 
% reason_text(Question, Answer, Sentence): user-friendly meaning of each answer
reason_text(passengers_six_or_more, yes, 'You regularly carry more than 5 people, so seating capacity is the deciding factor.').
reason_text(passengers_six_or_more, no,  'You carry 5 people or fewer, so a standard-size cabin is enough.').
reason_text(offroad_capable,        yes, 'You drive on rough or unpaved terrain, so ground clearance and a sturdy build matter.').
reason_text(offroad_capable,        no,  'You rarely leave paved roads, so off-road capability is not needed.').
reason_text(heavy_hauler,           yes, 'You need high cargo capacity or towing, so load space and strength matter.').
reason_text(heavy_hauler,           no,  'You do not need heavy cargo or towing capacity.').
reason_text(pure_ev,                yes, 'You prefer a pure electric powertrain.').
reason_text(pure_ev,                no,  'You do not require pure electric, so petrol or hybrid is acceptable.').
reason_text(city_commuter,          yes, 'You value easy parking and maneuverability over interior space.').
reason_text(city_commuter,          no,  'Interior space matters more to you than compact size.').
reason_text(performance_oriented,   yes, 'You prioritize sporty performance and handling over daily practicality.').
reason_text(performance_oriented,   no,  'Everyday practicality matters more to you than sporty performance.').
reason_text(higher_seating,  yes, 'You prefer a higher driving position, which gives a better view of the road and may help with visibility.').
reason_text(higher_seating,  no,  'You are comfortable with a normal driving position.').
reason_text(versatile_cargo, yes, 'You often carry groceries, luggage, sports equipment or other large items, so versatile cargo space is useful.').
reason_text(versatile_cargo, no,  'You do not often carry bulky items, so flexible cargo space is not a priority.').
 
% stored(Question, Answer): was this answer actually given by the user?
stored(Question, yes) :- yes(Question).
stored(Question, no)  :- no(Question).

% =========================================================================
% EXPLANATION
% =========================================================================
explain(Vehicle) :-
    description(Vehicle, Desc),
    format('What it is:~n  ~w~n~n', [Desc]),
    format('Why it fits your needs:~n'),
    rationale(Vehicle, Items),
    forall(( member(Q-A, Items), stored(Q, A), reason_text(Q, A, Sentence) ),
           format('  - ~w~n', [Sentence])),
    tradeoff(Vehicle, Tradeoff),
    format('~nKeep in mind:~n  ~w~n~n', [Tradeoff]).