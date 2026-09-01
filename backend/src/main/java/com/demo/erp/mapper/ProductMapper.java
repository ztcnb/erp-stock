package com.demo.erp.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.demo.erp.entity.Product;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 商品 Mapper
 */
public interface ProductMapper extends BaseMapper<Product> {

    /**
     * 分页联查商品(带分类名称),支持关键字与分类(含子孙分类)过滤
     */
    @Select("""
            <script>
            SELECT p.*, c.name AS category_name
            FROM product p
            LEFT JOIN product_category c ON c.id = p.category_id
            <where>
                <if test="keyword != null and keyword != ''">
                    AND (p.name ILIKE '%' || #{keyword} || '%' OR p.code ILIKE '%' || #{keyword} || '%')
                </if>
                <if test="categoryIds != null and categoryIds.size() > 0">
                    AND p.category_id IN
                    <foreach collection="categoryIds" item="cid" open="(" separator="," close=")">#{cid}</foreach>
                </if>
            </where>
            ORDER BY p.id
            </script>
            """)
    IPage<Product> selectPageJoin(IPage<Product> page,
                                  @Param("keyword") String keyword,
                                  @Param("categoryIds") List<Long> categoryIds);
}
