function [AggValues,AggMeasureNamesExtended] = GetAggValues(MeasuresStruct,Flags,AggMeasureNames,AggregateFunction)

% Get all values and corresponiding names in this struct
[AggValuesShuffled,AggMeasureNamesShuffled] = GetAggValuesSub(MeasuresStruct,MeasuresStruct.NSamples,Flags,AggregateFunction);

% Re-order measure names and values
N_NewMeas = size(AggMeasureNamesShuffled,1);
N_OldMeas = size(AggMeasureNames,1);
AggMeasureNamesExtended = AggMeasureNames;
AggValues = nan(N_OldMeas,1);
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
        AggValues(NewIndex,1) = AggValuesShuffled(i,1);
    else
        AggValues(OldIndex,1) = AggValuesShuffled(i,1);
    end
end


function [AggValuesSub,AggMeasureNamesSub] = GetAggValuesSub(MeasuresStructSub,NSamplesSub,FlagsSub,AggregateFunction)
AggMeasureNamesSub = {};
Index = 0;
FNs = fieldnames(MeasuresStructSub);
for FNnr = 1:size(FNs,1),
    FN = FNs{FNnr};
    if ~isstruct(MeasuresStructSub.(FN))
        Index = Index + 1;
        AggMeasureNamesSub{Index,1} = {FN};
        AggValuesSub(Index,1) = AggregateEpisodeValues(MeasuresStructSub.(FN),NSamplesSub,FlagsSub,AggregateFunction);
    else
        [AggValuesRec,AggMeasureNamesRec] = GetAggValuesSub(MeasuresStructSub.(FN),NSamplesSub,FlagsSub,AggregateFunction);
        NMeasRec = size(AggMeasureNamesRec,1);
        for RecMeasNameNr = 1:NMeasRec,
            AggMeasureNamesRec{RecMeasNameNr,1} = { FN, AggMeasureNamesRec{RecMeasNameNr,1}{:,:} };
        end
        AggMeasureNamesSub(Index+(1:NMeasRec),1) = AggMeasureNamesRec;
        AggValuesSub(Index+(1:NMeasRec),1) = AggValuesRec;
        Index = Index + NMeasRec;
    end
end

