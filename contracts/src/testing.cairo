#[cfg(test)]
mod tests {
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::ContractAddress;
    use debug::PrintTrait;

    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // import test utils
    use dojo::test_utils::{spawn_test_world, deploy_contract};

    // import model structs
    // the lowercase structs hashes generated by the compiler
    use castle_hexapolis::models::{
        Tile, TileType, Score, RemainingMoves, PlayerID, PlayerAddress, GameData, tile, score,
        remaining_moves, player_id, player_address, game_data
    };

    // import actions dojo contract
    use castle_hexapolis::actions::actions;

    // import interface
    use castle_hexapolis::interface::{IActions, IActionsDispatcher, IActionsDispatcherTrait};

    // import config
    use castle_hexapolis::config::{GRID_SIZE, REMAINING_MOVES_DEFAULT};

    // NOTE: Spawn world helper function
    // 1. deploys world contract
    // 2. deploys actions contract
    // 3. sets models within world
    // 4. returns caller, world dispatcher and actions dispatcher for use in testing!
    fn spawn_world() -> (ContractAddress, IWorldDispatcher, IActionsDispatcher) {
        let caller = starknet::contract_address_const::<'jon'>();

        // This sets caller for current function, but not passed to called contract functions
        starknet::testing::set_caller_address(caller);

        // This sets caller for called contract functions.
        starknet::testing::set_contract_address(caller);

        // NOTE: Models
        // we create an array here to pass to spawn_test_world. This 'sets' the models within the world.
        let mut models = array![
            tile::TEST_CLASS_HASH,
            score::TEST_CLASS_HASH,
            remaining_moves::TEST_CLASS_HASH,
            player_id::TEST_CLASS_HASH,
            player_address::TEST_CLASS_HASH,
            game_data::TEST_CLASS_HASH
        ];

        // deploy world with models
        let world = spawn_test_world(models);

        // deploy systems contract
        let contract_address = world
            .deploy_contract('actions', actions::TEST_CLASS_HASH.try_into().unwrap());

        // returns
        (caller, world, IActionsDispatcher { contract_address })
    }

    #[test]
    #[available_gas(30000000)]
    fn spawn_test() {
        let (caller, world, actions_) = spawn_world();

        actions_.spawn();

        // Get player ID
        let player_id = get!(world, caller, (PlayerID)).player_id;
        assert(1 == player_id, 'incorrect id');

        // Get player score and remaining moves
        let (score, remaining_moves) = get!(world, player_id, (Score, RemainingMoves));
        assert(score.score == 0, 'incorrect score');
        assert(remaining_moves.moves == REMAINING_MOVES_DEFAULT, 'incorrect remaining moves');

        // get player id
        let tile = get!(world, (GRID_SIZE, GRID_SIZE), (Tile));
        assert(tile.player_id == player_id, 'Center tile is not set');
        assert(tile.tile_type == TileType::Center, 'incorrect tile type');
    }

// #[test]
// #[available_gas(30000000)]
// fn dead_test() {
//     let (caller, world, actions_) = spawn_world();

//     actions_.spawn('r');
//     // Get player ID
//     let player_id = get!(world, caller, (PlayerID)).id;

//     let (position, rps_type, energy) = get!(world, player_id, (Position, RPSType, Energy));

//     // kill player
//     actions::player_dead(world, player_id);

//     // player models should be 0
//     let (position, rps_type, energy) = get!(world, player_id, (Position, RPSType, Energy));
//     assert(0 == position.x, 'incorrect position.x');
//     assert(0 == position.y, 'incorrect position.y');
//     assert(0 == energy.amt, 'incorrect energy');
// }

// #[test]
// #[available_gas(30000000)]
// fn random_spawn_test() {
//     let (caller, world, actions_) = spawn_world();

//     actions_.spawn('r');
//     // Get player ID
//     let pos_p1 = get!(world, get!(world, caller, (PlayerID)).id, (Position));

//     let caller = starknet::contract_address_const::<'jim'>();
//     starknet::testing::set_contract_address(caller);
//     actions_.spawn('r');
//     // Get player ID
//     let pos_p2 = get!(world, get!(world, caller, (PlayerID)).id, (Position));

//     assert(pos_p1.x != pos_p2.x, 'spawn pos.x same');
//     assert(pos_p1.y != pos_p2.y, 'spawn pos.x same');
// }

// #[test]
// #[available_gas(30000000)]
// fn random_duplicate_spawn_test() {
//     let (caller, world, actions_) = spawn_world();

//     let id = 16;
//     let (x, y) = actions::spawn_coords(world, caller.into(), id);

//     // Simulate player #5 on that location
//     set!(world, (PlayerAtPosition { x, y, id: 5 }));

//     let (x_, y_) = actions::spawn_coords(world, caller.into(), id);

//     assert(x != x_, 'spawn pos.x same');
//     assert(y != y_, 'spawn pos.x same');
// }

// #[test]
// #[available_gas(30000000)]
// fn moves_test() {
//     let (caller, world, actions_) = spawn_world();

//     actions_.spawn('r');

//     // Get player ID
//     let player_id = get!(world, caller, (PlayerID)).id;
//     assert(1 == player_id, 'incorrect id');

//     let (spawn_pos, spawn_energy) = get!(world, player_id, (Position, Energy));

//     actions_.move(Direction::Up);
//     // Get player from id
//     let (pos, energy) = get!(world, player_id, (Position, Energy));

//     // assert player moved and energy was deducted
//     assert(energy.amt == spawn_energy.amt - MOVE_ENERGY_COST, 'incorrect energy');
//     assert(spawn_pos.x == pos.x, 'incorrect position.x');
//     assert(spawn_pos.y - 1 == pos.y, 'incorrect position.y');
// }

// #[test]
// #[available_gas(30000000)]
// fn player_at_position_test() {
//     let (caller, world, actions_) = spawn_world();

//     actions_.spawn('r');

//     // Get player ID
//     let player_id = get!(world, caller, (PlayerID)).id;

//     // Get player position
//     let Position{x, y, id } = get!(world, player_id, Position);

//     // Player should be at position
//     assert(actions::player_at_position(world, x, y) == player_id, 'player should be at pos');

//     // Player moves
//     actions_.move(Direction::Up);

//     // Player shouldn't be at old position
//     assert(actions::player_at_position(world, x, y) == 0, 'player should not be at pos');

//     // Get new player position
//     let Position{x, y, id } = get!(world, player_id, Position);

//     // Player should be at new position
//     assert(actions::player_at_position(world, x, y) == player_id, 'player should be at pos');
// }

// // NOTE: Internal function tests

// #[test]
// #[available_gas(30000000)]
// fn encounter_test() {
//     let (caller, world, actions_) = spawn_world();
//     assert(false == actions::encounter_win('r', 'p'), 'R v P should lose');
//     assert(true == actions::encounter_win('r', 's'), 'R v S should win');
//     assert(false == actions::encounter_win('s', 'r'), 'S v R should lose');
//     assert(true == actions::encounter_win('s', 'p'), 'S v P should win');
//     assert(false == actions::encounter_win('p', 's'), 'P v S should lose');
//     assert(true == actions::encounter_win('p', 'r'), 'P v R should win');
// }

// #[test]
// #[available_gas(2000000)]
// #[should_panic()]
// fn encounter_rock_tie_panic() {
//     actions::encounter_win('r', 'r');
// }

// #[test]
// #[available_gas(2000000)]
// #[should_panic()]
// fn encounter_paper_tie_panic() {
//     actions::encounter_win('p', 'p');
// }

// #[test]
// #[available_gas(2000000)]
// #[should_panic()]
// fn encounter_scissor_tie_panic() {
//     actions::encounter_win('s', 's');
// }
}
