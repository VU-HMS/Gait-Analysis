function ArrayOfStructuresNew = AddFieldsInArrayOfStructures(ArrayOfStructures,NewFieldNames,FunctionForFields,FieldNames1,FieldNames2)
ArrayOfStructuresNew = ArrayOfStructures;
if ~iscell(NewFieldNames), NewFieldNames = {NewFieldNames}; end
for i=1:numel(ArrayOfStructuresNew),
    if FieldsExist(ArrayOfStructuresNew(i),FieldNames1) ...
            && FieldsExist(ArrayOfStructuresNew(i),FieldNames2)
        NewFieldContent = FunctionForFields(GetField(ArrayOfStructuresNew(i),FieldNames1),GetField(ArrayOfStructuresNew(i),FieldNames2));
        switch size(NewFieldNames(:),1)
            case 1
                ArrayOfStructuresNew(i).(NewFieldNames{1}) = NewFieldContent;
            case 2
                ArrayOfStructuresNew(i).(NewFieldNames{1}).(NewFieldNames{2}) = NewFieldContent;
            case 3
                ArrayOfStructuresNew(i).(NewFieldNames{1}).(NewFieldNames{2}).(NewFieldNames{3}) = NewFieldContent;
            case 4
                ArrayOfStructuresNew(i).(NewFieldNames{1}).(NewFieldNames{2}).(NewFieldNames{3}).(NewFieldNames{4}) = NewFieldContent;
            case 5
                ArrayOfStructuresNew(i).(NewFieldNames{1}).(NewFieldNames{2}).(NewFieldNames{3}).(NewFieldNames{4}).(NewFieldNames{5}) = NewFieldContent;
        end
    end
end

function [DoExist] = FieldsExist(Structure,FieldNames)
if ~iscell(FieldNames), FieldNames = {FieldNames}; end
if size(FieldNames(:),1) == 0
    DoExist = true;
elseif size(FieldNames(:),1) == 1
    DoExist = isfield(Structure,FieldNames);
elseif size(FieldNames(:),1) > 1
    DoExist = isfield(Structure,FieldNames{1}) && FieldsExist(Structure.(FieldNames{1}),FieldNames{2:end});
end

function [FieldContent] = GetField(Structure,FieldNames)
if ~iscell(FieldNames), FieldNames = {FieldNames}; end
if size(FieldNames(:),1) == 0
    FieldContent = Structure;
elseif size(FieldNames(:),1) == 1
    FieldContent = Structure.(FieldNames{1});
elseif size(FieldNames(:),1) > 1
    FieldContent = GetField(Structure.(FieldNames{1}),FieldNames{2:end});
end
