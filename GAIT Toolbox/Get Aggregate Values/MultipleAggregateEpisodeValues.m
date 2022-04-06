function Aggregates = MultipleAggregateEpisodeValues(Values,Flags,AggregateFunction,FunctionArguments)

Aggregates = AggregateFunction(Values(Flags),FunctionArguments);
