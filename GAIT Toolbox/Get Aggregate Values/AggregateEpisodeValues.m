function Aggregate = AggregateEpisodeValues(Values,NSamples,Flags,AggregateFunction)

Aggregate = AggregateFunction(Values(Flags),NSamples(Flags));
