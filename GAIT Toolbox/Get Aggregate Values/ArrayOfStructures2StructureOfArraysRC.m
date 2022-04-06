function StructureOfArrays = ArrayOfStructures2StructureOfArraysRC(ArrayOfStructures)

StructSize = size(ArrayOfStructures);

StructureOfArrays = struct();

for i=1:prod(StructSize),
    FNs1 = fieldnames(ArrayOfStructures(i));
    for FNnr1 = 1:size(FNs1,1),
        FN1 = FNs1{FNnr1};
        if ~isstruct(ArrayOfStructures(i).(FN1))
            FieldSize = size(ArrayOfStructures(i).(FN1));
            ProdFieldSize = prod(FieldSize);
            if ProdFieldSize == 1
                if ~(   isfield(StructureOfArrays,FN1) )
                    StructureOfArrays.(FN1) = nan(StructSize);
                elseif isstruct(StructureOfArrays.(FN1))
                    error('Fields must be all scalar or all non-scalar across structures if present (field %s)',FN1);
                end
                StructureOfArrays.(FN1)(i) = ArrayOfStructures(i).(FN1);
            else
                if ~(   isfield(StructureOfArrays,FN1) )
                    StructureOfArrays.(FN1) = struct();
                elseif ~isstruct(StructureOfArrays.(FN1))
                    error('Fields must be all scalar or all non-scalar across structures if present (field %s)',FN1);
                end
                for Row = 1:FieldSize(1),
                    RowName = sprintf('r%d',Row);
                    for Col = 1:FieldSize(2),
                        ColName = sprintf('c%d',Col);
                        if ~(isfield(StructureOfArrays.(FN1),RowName)...
                                && isfield(StructureOfArrays.(FN1).(RowName),ColName))
                            StructureOfArrays.(FN1).(RowName).(ColName) = nan(StructSize);
                        end
                        StructureOfArrays.(FN1).(RowName).(ColName)(i) = ArrayOfStructures(i).(FN1)(Row,Col);
                    end
                end
            end
        else
            % repeat for depth 2
            FNs2 = fieldnames(ArrayOfStructures(i).(FN1));
            for FNnr2 = 1:size(FNs2,1),
                FN2 = FNs2{FNnr2};
                if ~isstruct(ArrayOfStructures(i).(FN1).(FN2))
                    FieldSize = size(ArrayOfStructures(i).(FN1).(FN2));
                    ProdFieldSize = prod(FieldSize);
                    if ProdFieldSize == 1
                        if ~(   isfield(StructureOfArrays,FN1)...
                                && isfield(StructureOfArrays.(FN1),FN2) )
                            StructureOfArrays.(FN1).(FN2) = nan(StructSize);
                        elseif isstruct(StructureOfArrays.(FN1).(FN2))
                            error('Fields must be all scalar or all non-scalar across structures if present (field %s.%s)',FN1,FN2);
                        end
                        StructureOfArrays.(FN1).(FN2)(i) = ArrayOfStructures(i).(FN1).(FN2);
                    else
                        if ~(   isfield(StructureOfArrays,FN1)...
                                && isfield(StructureOfArrays.(FN1),FN2) )
                            StructureOfArrays.(FN1).(FN2) = struct();
                        elseif ~isstruct(StructureOfArrays.(FN1).(FN2))
                            error('Fields must be all scalar or all non-scalar across structures if present (field %s.%s)',FN1,FN2);
                        end
                        for Row = 1:FieldSize(1),
                            RowName = sprintf('r%d',Row);
                            for Col = 1:FieldSize(2),
                                ColName = sprintf('c%d',Col);
                                if ~(isfield(StructureOfArrays.(FN1).(FN2),RowName)...
                                        && isfield(StructureOfArrays.(FN1).(FN2).(RowName),ColName))
                                    StructureOfArrays.(FN1).(FN2).(RowName).(ColName) = nan(StructSize);
                                end
                                StructureOfArrays.(FN1).(FN2).(RowName).(ColName)(i) = ArrayOfStructures(i).(FN1).(FN2)(Row,Col);
                            end
                        end
                    end
                else
                    % repeat for depth 3
                    FNs3 = fieldnames(ArrayOfStructures(i).(FN1).(FN2));
                    for FNnr3 = 1:size(FNs3,1),
                        FN3 = FNs3{FNnr3};
                        if ~isstruct(ArrayOfStructures(i).(FN1).(FN2).(FN3))
                            FieldSize = size(ArrayOfStructures(i).(FN1).(FN2).(FN3));
                            ProdFieldSize = prod(FieldSize);
                            if ProdFieldSize == 1
                                if ~(   isfield(StructureOfArrays,FN1)...
                                        && isfield(StructureOfArrays.(FN1),FN2)...
                                        && isfield(StructureOfArrays.(FN1).(FN2),FN3) )
                                    StructureOfArrays.(FN1).(FN2).(FN3) = nan(StructSize);
                                elseif isstruct(StructureOfArrays.(FN1).(FN2).(FN3))
                                    error('Fields must be all scalar or all non-scalar across structures if present (field %s.%s.%s)',FN1,FN2,FN3);
                                end
                                StructureOfArrays.(FN1).(FN2).(FN3)(i) = ArrayOfStructures(i).(FN1).(FN2).(FN3);
                            else
                                if ~(   isfield(StructureOfArrays,FN1)...
                                        && isfield(StructureOfArrays.(FN1),FN2)...
                                        && isfield(StructureOfArrays.(FN1).(FN2),FN3) )
                                    StructureOfArrays.(FN1).(FN2).(FN3) = struct();
                                elseif ~isstruct(StructureOfArrays.(FN1).(FN2).(FN3))
                                    error('Fields must be all scalar or all non-scalar across structures if present (field %s.%s.%s)',FN1,FN2,FN3);
                                end
                                for Row = 1:FieldSize(1),
                                    RowName = sprintf('r%d',Row);
                                    for Col = 1:FieldSize(2),
                                        ColName = sprintf('c%d',Col);
                                        if ~(isfield(StructureOfArrays.(FN1).(FN2).(FN3),RowName)...
                                                && isfield(StructureOfArrays.(FN1).(FN2).(FN3).(RowName),ColName))
                                            StructureOfArrays.(FN1).(FN2).(FN3).(RowName).(ColName) = nan(StructSize);
                                        end
                                        StructureOfArrays.(FN1).(FN2).(FN3).(RowName).(ColName)(i) = ArrayOfStructures(i).(FN1).(FN2).(FN3)(Row,Col);
                                    end
                                end
                            end
                        else
                            % repeat for depth 4
                            FNs4 = fieldnames(ArrayOfStructures(i).(FN1).(FN2).(FN3));
                            for FNnr4 = 1:size(FNs4,1),
                                FN4 = FNs4{FNnr4};
                                if ~isstruct(ArrayOfStructures(i).(FN1).(FN2).(FN3).(FN4))
                                    FieldSize = size(ArrayOfStructures(i).(FN1).(FN2).(FN3).(FN4));
                                    ProdFieldSize = prod(FieldSize);
                                    if ProdFieldSize == 1
                                        if ~(   isfield(StructureOfArrays,FN1)...
                                                && isfield(StructureOfArrays.(FN1),FN2)...
                                                && isfield(StructureOfArrays.(FN1).(FN2),FN3)...
                                                && isfield(StructureOfArrays.(FN1).(FN2).(FN3),FN4) )
                                            StructureOfArrays.(FN1).(FN2).(FN3).(FN4) = nan(StructSize);
                                        elseif isstruct(StructureOfArrays.(FN1).(FN2).(FN3).(FN4))
                                            error('Fields must be all scalar or all non-scalar across structures if present (field %s.%s.%s.%s)',FN1,FN2,FN3,FN4);
                                        end
                                        StructureOfArrays.(FN1).(FN2).(FN3).(FN4)(i) = ArrayOfStructures(i).(FN1).(FN2).(FN3).(FN4);
                                    else
                                        if ~(   isfield(StructureOfArrays,FN1)...
                                                && isfield(StructureOfArrays.(FN1),FN2)...
                                                && isfield(StructureOfArrays.(FN1).(FN2),FN3)...
                                                && isfield(StructureOfArrays.(FN1).(FN2).(FN3),FN4) )
                                            StructureOfArrays.(FN1).(FN2).(FN3).(FN4) = struct();
                                        elseif ~isstruct(StructureOfArrays.(FN1).(FN2).(FN3).(FN4))
                                            error('Fields must be all scalar or all non-scalar across structures if present (field %s.%s.%s.%s)',FN1,FN2,FN3,FN4);
                                        end
                                        for Row = 1:FieldSize(1),
                                            RowName = sprintf('r%d',Row);
                                            for Col = 1:FieldSize(2),
                                                ColName = sprintf('c%d',Col);
                                                if ~(isfield(StructureOfArrays.(FN1).(FN2).(FN3).(FN4),RowName)...
                                                        && isfield(StructureOfArrays.(FN1).(FN2).(FN3).(FN4).(RowName),ColName))
                                                    StructureOfArrays.(FN1).(FN2).(FN3).(FN4).(RowName).(ColName) = nan(StructSize);
                                                end
                                                StructureOfArrays.(FN1).(FN2).(FN3).(FN4).(RowName).(ColName)(i) = ArrayOfStructures(i).(FN1).(FN2).(FN3).(FN4)(Row,Col);
                                            end
                                        end
                                    end
                                else
                                    % repeat for depth 5
                                    FNs5 = fieldnames(ArrayOfStructures(i).(FN1).(FN2).(FN3).(FN4));
                                    for FNnr5 = 1:size(FNs5,1),
                                        FN5 = FNs5{FNnr5};
                                        if ~isstruct(ArrayOfStructures(i).(FN1).(FN2).(FN3).(FN4).(FN5))
                                            FieldSize = size(ArrayOfStructures(i).(FN1).(FN2).(FN3).(FN4).(FN5));
                                            ProdFieldSize = prod(FieldSize);
                                            if ProdFieldSize == 1
                                                if ~(   isfield(StructureOfArrays,FN1)...
                                                        && isfield(StructureOfArrays.(FN1),FN2)...
                                                        && isfield(StructureOfArrays.(FN1).(FN2),FN3)...
                                                        && isfield(StructureOfArrays.(FN1).(FN2).(FN3),FN4)...
                                                        && isfield(StructureOfArrays.(FN1).(FN2).(FN3).(FN4),FN5) )
                                                    StructureOfArrays.(FN1).(FN2).(FN3).(FN4).(FN5) = nan(StructSize);
                                                elseif isstruct(StructureOfArrays.(FN1).(FN2).(FN3).(FN4).(FN5))
                                                    error('Fields must be all scalar or all non-scalar across structures if present (field %s.%s.%s.%s.%s)',FN1,FN2,FN3,FN4,FN5);
                                                end
                                                StructureOfArrays.(FN1).(FN2).(FN3).(FN4).(FN5)(i) = ArrayOfStructures(i).(FN1).(FN2).(FN3).(FN4).(FN5);
                                            else
                                                if ~(   isfield(StructureOfArrays,FN1)...
                                                        && isfield(StructureOfArrays.(FN1),FN2)...
                                                        && isfield(StructureOfArrays.(FN1).(FN2),FN3)...
                                                        && isfield(StructureOfArrays.(FN1).(FN2).(FN3),FN4)...
                                                        && isfield(StructureOfArrays.(FN1).(FN2).(FN3).(FN4),FN5) )
                                                    StructureOfArrays.(FN1).(FN2).(FN3).(FN4).(FN5) = struct();
                                                elseif ~isstruct(StructureOfArrays.(FN1).(FN2).(FN3).(FN4).(FN5))
                                                    error('Fields must be all scalar or all non-scalar across structures if present (field %s.%s.%s.%s.%s)',FN1,FN2,FN3,FN4,FN5);
                                                end
                                                for Row = 1:FieldSize(1),
                                                    RowName = sprintf('r%d',Row);
                                                    for Col = 1:FieldSize(2),
                                                        ColName = sprintf('c%d',Col);
                                                        if ~(isfield(StructureOfArrays.(FN1).(FN2).(FN3).(FN4).(FN5),RowName)...
                                                                && isfield(StructureOfArrays.(FN1).(FN2).(FN3).(FN4).(FN5).(RowName),ColName))
                                                            StructureOfArrays.(FN1).(FN2).(FN3).(FN4).(FN5).(RowName).(ColName) = nan(StructSize);
                                                        end
                                                        StructureOfArrays.(FN1).(FN2).(FN3).(FN4).(FN5).(RowName).(ColName)(i) = ArrayOfStructures(i).(FN1).(FN2).(FN3).(FN4).(FN5)(Row,Col);
                                                    end
                                                end
                                            end
                                        else
                                            % If needed add depth 6
                                            error('Structure has depth higher than 5, update program to handle such a structure (field %s.%s.%s.%s.%s.%s)',FN1,FN2,FN3,FN4,FN5,FN6);
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end


