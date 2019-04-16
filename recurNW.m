classdef recurNW
    %RECURNW Summary of this class goes here
    %   This algorith works through every possible path that could occur
    %
    
    properties
        minTotalCost;
        minCostPath;
        nirsDiffSeq;%i
        pyDiffSeq;%j
        j_compare;
        i_compare;
        i_max;
        j_max;
        gapPenalty = -5;
        
    end
    properties(Constant)
        gapPenaltyConst = -5;
        
    end
    methods(Static)
        
        function pathFig = plotPath(path, i_labels, j_labels)
            
            pathFig = figure;
            plot(path(:,2),path(:,1),'-o');
            set(gca,'Ydir','reverse')
            xlim([0,path(end,2)+1])
            ylim([0,path(end,1)+1])
            grid on
            
            labels = cell(size(path,1),1);
            for pt = 1:size(path,1)
                labels{pt} = [ num2str(round(i_labels(path(pt,1)),2)) ',' num2str(round(j_labels(path(pt,2)),2)) ];
            end
            text(path(:,2)-.4,path(:,1)-.25,labels)
        end
        
        function score = calcScore(one,two)
            score = -abs(diff([one;two]));
        end
        
        function obj = recur(obj,currCost,currPath,i,j)
            minFlag = 0;
            minUpdates = 0;
            
            %this block executes when we have not reached the bottom right
            %corner. If either has reached its max then we want to step
            %out until we have gotten to a point in the path where we can
            %make a truly unique path and not return to where we were ( ie
            %we dont keep going right after down fails if we are on the max
            %row because every option to go right will only go right and
            %not down or next because they exist which repeats the same path until we return to the row above)
            
            
            %at this point we are at the bottom right hand corner so lets
            %find the costs and see if it is the minimum cost so far
            if(i==obj.i_max&&j==obj.j_max)
                %end step of the recursion we should only get here if we
                %have calculated the full path

                %currCost = currCost + recurNW.calcScore(obj.nirsDiffSeq(i),obj.pyDiffSeq(j));
                if(isempty(obj.minTotalCost))
                    obj.minTotalCost = currCost;
                else
                    obj.minTotalCost = max(currCost,obj.minTotalCost);% we max because if all costs are negative the ones closer to 0 are greater than negatives further from 0
                    %given all costs are negative we want the "minimum" of
                    %those costs
                    minFlag = 1;%signal that we have set a minimum
                    minUpdates = minUpdates+1;
                    
                end
                if(minFlag == 1)
                    currPath = [currPath;i,j];%append final part of path ie j_max and i_max coord
                    obj.minCostPath = currPath;
                    minFlag = 0;
                    if ~mod(minUpdates,100) % only display every 100 update
                        fprintf('Update %g sets new min %g\n',minUpdates,obj.minTotalCost);
                    end
                end
                
                %if we are in the last element of either sequence
            end
            if(i<obj.i_max||j<obj.j_max)
                if(i==1&&j==1)
                    obj.gapPenalty = 0;
                    
                else
                    obj.gapPenalty = obj.gapPenaltyConst;
                end
                
                %First call to enter into the recursion. It will
                %systematically go through every one of the possible
                %combinations of down,right and next
                %these three moves are the only possible moves we can take
                %through this matrix
                
                [currCost,currPath,i,j,obj] = recurNW.down(obj,currCost,currPath,i,j);
                
                [currCost,currPath,i,j,obj] = recurNW.right(obj,currCost,currPath,i,j);
                
                [currCost,currPath,i,j,obj] = recurNW.next(obj,currCost,currPath,i,j);
            end
            
            
        end
        
        function [currCost,currPath,i,j,obj] = down(obj,currCost,currPath,i,j)
            %ensure we are not in the bottom row already
            if(i<obj.i_max)
                if(i==1&&i==1)%we need to check to make sure we are not accumulating the first gap into the compare accum 
                    obj.i_compare = -obj.nirsDiffSeq(1); 
                elseif(isempty(obj.i_compare))
                    obj.i_compare = 0;
                end
            
                
                %keeps track of the current cost of a row or column based
                %on the gaps weve made. Only used in down and right
                obj.i_compare = obj.i_compare+obj.nirsDiffSeq(i);
                %update our current path with the current i&j
                currPath = [currPath;i,j];
                currCost = obj.gapPenalty+currCost;% + recurNW.calcScore(obj.nirsDiffSeq(i),obj.pyDiffSeq(j));
                %recursion step
                
                i=i+1;
                
            elseif(i==obj.i_max)%we in j
                %finish up the j sequence
                while(j<obj.j_max)
                    j= j+1;
                    currPath = [currPath;i,j];
                    currCost = currCost + obj.gapPenalty;
                end
            end
            obj = recurNW.recur(obj,currCost,currPath,i,j);
        end
        
        function [currCost,currPath,i,j,obj] = right(obj,currCost,currPath,i,j)
            %ensure we are not in the rightmost column already;
            if(j<obj.j_max)
                if(j==1&&i==1)
                    %we need to check to make sure we are not accumulating the first gap into the compare accum
                    obj.j_compare = -obj.pyDiffSeq(1);
                elseif(isempty(obj.j_compare))
                    obj.j_compare = 0;
                end
                
                
                %keeps track of the current cost of a row or column based
                %on the gaps weve made. Only used in down and right
                obj.j_compare = obj.j_compare + obj.pyDiffSeq(j);
                %update our current path with the current i&j
                currPath = [currPath;i,j];
                currCost = obj.gapPenalty + currCost;% + recurNW.calcScore(obj.nirsDiffSeq(i),obj.pyDiffSeq(j));
                %recursion step
                j=j+1;
                
            
            else%we in i
                %finish up the i sequence
                while(j<obj.j_max)
                    j=j+1;
                    currPath = [currPath;i,j];
                    currCost = currCost + obj.gapPenalty;
                end
            end
            obj = recurNW.recur(obj,currCost,currPath,i,j);
        end
        
        function [currCost,currPath,i,j,obj] = next(obj,currCost,currPath,i,j)
            %ensure we can execute next without going out of bounds on
            %nirsSeq and pySeq
            if(i==3&&j==2)
                fprintf("here");
            end
            if(i<obj.i_max&&j<obj.j_max)
                if(obj.j_compare==0)
                    obj.j_compare = obj.pyDiffSeq(j);
                end
                if(obj.i_compare==0)
                    obj.i_compare = obj.pyDiffSeq(i);
                end
                    
                    
                %update our current path with the current i&j
                currPath = [currPath;i,j];
                currCost = currCost + recurNW.calcScore(obj.j_compare,obj.i_compare);
                fprintf('matched %g with %g for new cost %g\n',obj.j_compare,obj.i_compare,currCost);
                %reset our compare values because if we have gone to next
                %we have compared all actively gapped segments;
                obj.i_compare = 0;
                obj.j_compare = 0;
                %recursion step
                i=i+1;
                j=j+1;
                obj = recurNW.recur(obj,currCost,currPath,i,j);
            end
        end
        
        
        
        
        %to be finished
        function [nirsGapped,logGapped,rebuiltTimes] = rebuiltTriggerTimes(nirs,pylog,matchPath)
            for i = 1:length(matchPath)
                
            end
        end
        
        
        
    end
    
    methods
        function obj = recurNW(m_nirsDiffSeq,m_pyDiffSeq)
            %setup the initial object
            obj.nirsDiffSeq = m_nirsDiffSeq;
            obj.pyDiffSeq = m_pyDiffSeq;
            obj = obj.start();
            
        end
        function obj = start(obj)
            %wrapper to execute all necessary startup procedures and begin
            %the recursion
            obj.j_max = length(obj.pyDiffSeq);
            obj.i_max = length(obj.nirsDiffSeq);
            
            %initiate all values and start the recursion at the first case
            
            currCost = 0;
            currPath = [];
            i = 1;
            j = 1;
            
            
            obj = recurNW.recur(obj,currCost,currPath,i,j);
            
            recurNW.plotPath(obj.minCostPath,obj.nirsDiffSeq,obj.pyDiffSeq);
            text(obj.minCostPath(end,2),obj.minCostPath(end,1)+.5,num2str(round(obj.minTotalCost,1)));
        end
        
    end
end

