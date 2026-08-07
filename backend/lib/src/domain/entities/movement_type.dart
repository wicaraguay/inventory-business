/// A stock movement is either an inbound entry or an outbound exit.
/// `name` maps 1:1 to the `type` check constraint in the DB.
enum MovementType { entry, exit }
