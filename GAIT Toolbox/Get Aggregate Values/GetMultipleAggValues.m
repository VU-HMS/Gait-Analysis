function [AggValues,AggMeasureNamesExtended] = GetMultipleAggValues(...
    MeasuresStruct,Flags,AggMeasureNames,AggregateFunction,N_Aggregators,FunctionArguments)

% Get all values and corresponiding names in this struct
[AggValuesShuffled,AggMeasureNamesShuffled] = GetAggValuesSub(...
    MeasuresStruct,Flags,AggregateFunction,N_Aggregators,FunctionArguments);

% Re-order measure names and values
N_NewMeas = size(AggMeasureNamesShuffled,1);
N_OldMeas = size(AggMeasureNames,1);
AggMeasureNamesExtended = AggMeasureNames;
AggValues = nan(N_OldMeas,N_Aggregators);
NewIndex = N_OldMeas; 
for i=1:N_NewMeas,
    Depth = size(AggMeasureNamesShuffled{i,1},2);
    OldIndex = nan;
    for j=1:N_OldMeas
        if size(AggMeasureNames{j,1},2)==Depth,
            if all(strcmp(AggMeasureNamesShuffled{i,1},AggMeasureNames{j,1}))
                OldIndex = j;
                break
            end
        end
    end
    if isnan(OldIndex)
        NewIndex = NewIndex + 1;
        AggMeasureNamesExtended{NewIndex,1} = AggMeasureNamesShuffled{i,1};
        AggValues(NewIndex,:) = AggValuesShuffled(i,:);
    else
        AggValues(OldIndex,:) = AggValuesShuffled(i,:);
    end
end


function [AggValuesSub,AggMeasureNamesSub] = GetAggValuesSub(...
    MeasuresStructSub,FlagsSub,AggregateFunction,N_Aggregators,FunctionArguments)
AggMeasureNamesSub = {};
Index = 0;
FNs = fieldnames(MeasuresStructSub);
for FNnr = 1:size(FNs,1),
    FN = FNs{FNnr};
    if ~isstruct(MeasuresStructSub.(FN))
        Index = Index + 1;
        AggMeasureNamesSub{Index,1} = {FN};
        AggValuesSub(Index,1:N_Aggregators) = MultipleAggregateEpisodeValues(MeasuresStructSub.(FN),FlagsSub,AggregateFunction,FunctionArguments);
    else
        [AggValuesRec,AggMeasureNamesRec] = GetAggValuesSub(MeasuresStructSub.(FN),FlagsSub,AggregateFunction,N_Aggregators,FunctionArguments);
        NMeasRec = size(AggMeasureNamesRec,1);
        for RecMeasNameNr = 1:NMeasRec,
            AggMeasureNamesRec{RecMeasNameNr,1} = { FN, AggMeasureNamesRec{RecMeasNameNr,1}{:,:} };
        end
        AggMeasureNamesSub(Index+(1:NMeasRec),1) = AggMeasureNamesRec;
        AggValuesSub(Index+(1:NMeasRec),1:N_Aggregators) = AggValuesRec;
        Index = Index + NMeasRec;
    end
end

